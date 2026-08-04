import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/mixin/snackbar_service.dart';
import 'package:rankmyroast/common_widgets/take_photo_bottom_modal_widget.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/create/widgets/time_section_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/create/widgets/form_section_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/create/widgets/group_form_section_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/create/widgets/widgets/image_content_widget.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Recipe? recipeToEdit;
  final Group? selectedGroup;
  final List<Group> groups;
  final bool? isCopying;

  const CreateRecipeScreen({
    super.key,
    this.recipeToEdit,
    this.selectedGroup,
    required this.groups,
    this.isCopying,
  });

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen>
    with SnackbarService {
  late final bool _isEditing;
  late final Recipe? _recipeToEdit;
  late final String? _recipeToEditImageUrl;

  late final String _labelText;

  File? _recipeImageFile;

  bool _isPublic = false;
  bool _isCreatingRecipe = false;
  bool _canSubmit = false;
  bool _includeTimeEstimations = false;
  bool _includeIngredients = false;
  bool _includeInstructions = false;
  bool _includeGroceryItems = false;
  bool _includeGroups = false;
  bool _hideTimeEstimations = false;
  bool _hideIngredients = false;
  bool _hideInstructions = false;
  bool _hideGroceryItems = false;
  bool _hideGroups = false;
  bool _removeImage = false;
  bool _isCopying = false;

  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _groceryItemsController = TextEditingController();
  final TextEditingController _groupsController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();

  final List<String> _ingredientsList = [];
  final List<String> _instructionsList = [];
  final List<String> _groceryList = [];

  final List<Group> _selectedGroups = [];

  @override
  void initState() {
    _isEditing = widget.recipeToEdit != null;
    _isCopying = widget.isCopying == true;

    if (_isEditing && !_isCopying) {
      _applyRecipeData(
        widget.recipeToEdit!,
        label: "Edit Recipe",
        includeImageUrl: true,
      );
      _getGroupsForRecipe();
    } else if (_isCopying) {
      _applyRecipeData(
        widget.recipeToEdit!,
        label: "Copy Recipe",
        includeImageUrl: false,
        nameSuffix: " Copy",
      );
    } else {
      _labelText = "Create Recipe";
      _recipeToEditImageUrl = null;
      _recipeToEdit = null;
    }

    super.initState();
  }

  void _applyRecipeData(
    Recipe recipe, {
    required String label,
    bool includeImageUrl = true,
    String nameSuffix = "",
  }) {
    _recipeToEdit = recipe;
    _recipeToEditImageUrl = includeImageUrl ? recipe.publicImageUrl : null;
    _labelText = label;
    _recipeNameController.text = recipe.name + nameSuffix;
    _prepTimeController.text =
        recipe.prepTime != null ? recipe.prepTime.toString() : "";
    _cookTimeController.text =
        recipe.cookTime != null ? recipe.cookTime.toString() : "";

    _ingredientsList.clear();
    _ingredientsList.addAll(recipe.ingredientList);
    _instructionsList.clear();
    _instructionsList.addAll(recipe.instructionsList);
    _groceryList.clear();
    _groceryList.addAll(recipe.groceriesList);

    _isPublic = recipe.isPublic;
    _canSubmit = true;

    _includeIngredients = _ingredientsList.isNotEmpty;
    _hideIngredients = !_includeIngredients;
    _includeInstructions = _instructionsList.isNotEmpty;
    _hideInstructions = !_includeInstructions;
    _includeGroceryItems = _groceryList.isNotEmpty;
    _hideGroceryItems = !_includeGroceryItems;
    _includeGroups = widget.selectedGroup != null;
    _hideGroups = !_includeGroups;
    _includeTimeEstimations =
        recipe.prepTime != null || recipe.cookTime != null;
    _hideTimeEstimations = !_includeTimeEstimations;
  }

  Future<void> _getGroupsForRecipe() async {
    if (widget.recipeToEdit == null) return;

    final groupsForRecipe = await SupabaseHelper.recipe.getGroupsForRecipe(
      widget.recipeToEdit!.id,
    );

    if (groupsForRecipe != null) {
      setState(() {
        _selectedGroups.addAll(groupsForRecipe);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,

        foregroundColor: Colors.white,
        title: Text(
          _labelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.recipeToEdit != null)
            IconButton(
              onPressed: () async {},
              icon: Icon(Icons.delete, color: Colors.white),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),

            onSelected: (String result) {
              if (result == 'Option 1') {
                _showHiddenFields();
              }
            },

            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Option 1',
                    child: Text('Show Hidden Items'),
                  ),
                ],
          ),
        ],
      ),
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(115, 0, 0, 0),
                      blurRadius: 10,
                      offset: Offset(2, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 24.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width: 128.w,
                            height: 128.w,
                            child: ImageContentWidget(
                              recipeImage: _recipeImageFile,
                              updateRecipeImage: _updateRecipeImage,
                              isEditing: _isEditing,
                              removeImage: _removeImage,
                              recipeImageUrl: _recipeToEditImageUrl,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Container(
                                    height: 42.h,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[600]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller: _recipeNameController,
                                      onChanged:
                                          (value) =>
                                              _recipeNameController
                                                      .text
                                                      .isNotEmpty
                                                  ? setState(() {
                                                    _canSubmit = true;
                                                  })
                                                  : setState(() {
                                                    _canSubmit = false;
                                                  }),
                                      decoration: InputDecoration(
                                        labelText: "Recipe Name",
                                        labelStyle: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,

                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      if (_ingredientsList.isNotEmpty) SizedBox(height: 8),

                      TimeSectionWidget(
                        includeSectionText: "Include Time Estimations",
                        includeSection: _includeTimeEstimations,
                        isHidden: _hideTimeEstimations,
                        onModify:
                            () => setState(() {
                              _includeTimeEstimations =
                                  !_includeTimeEstimations;
                            }),
                        onHide:
                            () => setState(() {
                              _hideTimeEstimations = true;
                            }),
                        controllerPrepTime: _prepTimeController,
                        controllerCookTime: _cookTimeController,
                        setParentState: setState,
                      ),

                      SizedBox(height: 16),

                      FormSectionWidget(
                        header: "Ingredients",
                        subtitle: "Add ingredients...",
                        isNumericalList: false,
                        controller: _ingredientsController,
                        itemsList: _ingredientsList,
                        includeSection: _includeIngredients,
                        includeSectionText: "Include Ingredients",
                        onModify:
                            () => setState(() {
                              _includeIngredients = !_includeIngredients;
                            }),
                        isHidden: _hideIngredients,
                        onHide:
                            () => setState(() {
                              _hideIngredients = true;
                            }),
                        setParentState: setState,
                        deleteFromParent:
                            (item) => _ingredientsList.remove(item),
                        updatePositionForParentList: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _ingredientsList.removeAt(oldIndex);
                          _ingredientsList.insert(newIndex, item);
                        },
                      ),

                      SizedBox(height: 16),

                      FormSectionWidget(
                        header: "Instructions",
                        subtitle: "Add instructions...",
                        isNumericalList: true,
                        controller: _instructionsController,
                        itemsList: _instructionsList,
                        includeSection: _includeInstructions,
                        includeSectionText: "Include Instructions",
                        onModify:
                            () => setState(() {
                              _includeInstructions = !_includeInstructions;
                            }),
                        isHidden: _hideInstructions,
                        onHide:
                            () => setState(() {
                              _hideInstructions = true;
                            }),
                        updatePositionForParentList: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _instructionsList.removeAt(oldIndex);
                          _instructionsList.insert(newIndex, item);
                        },
                        setParentState: setState,
                        deleteFromParent:
                            (item) => _instructionsList.remove(item),
                      ),

                      SizedBox(height: 16),

                      FormSectionWidget(
                        header: "Grocery Items",
                        subtitle: "Add items to purchase...",
                        isNumericalList: false,
                        controller: _groceryItemsController,
                        itemsList: _groceryList,
                        includeSection: _includeGroceryItems,
                        includeSectionText: "Include Grocery Items",
                        onModify:
                            () => setState(() {
                              _includeGroceryItems = !_includeGroceryItems;
                            }),
                        isHidden: _hideGroceryItems,
                        onHide:
                            () => setState(() {
                              _hideGroceryItems = true;
                            }),
                        setParentState: setState,
                        deleteFromParent: (item) => _groceryList.remove(item),
                        updatePositionForParentList: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _groceryList.removeAt(oldIndex);
                          _groceryList.insert(newIndex, item);
                        },
                      ),

                      SizedBox(height: 16),

                      GroupFormSectionWidget(
                        header: "Add to Groups",
                        subtitle: "Click to add groups...",
                        includeSectionText: "Add to your Groups",
                        isNumericalList: false,
                        includeSection: _includeGroups,
                        isHidden: _hideGroups,
                        onModify:
                            () => setState(() {
                              _includeGroups = !_includeGroups;
                            }),
                        onHide:
                            () => setState(() {
                              _hideGroups = true;
                            }),
                        controller: _groupsController,
                        itemsList: _selectedGroups,
                        groups: widget.groups,
                        setParentState: setState,
                        deleteFromParent:
                            (item) => _selectedGroups.removeWhere(
                              (group) => group.name == item,
                            ),
                      ),

                      // Row(
                      //   children: [
                      //     Checkbox(
                      //       value: _isPublic,
                      //       onChanged: (value) {
                      //         setState(() {
                      //           _isPublic = !_isPublic;
                      //         });
                      //       },
                      //       semanticLabel: "Make Recipe Public",
                      //     ),
                      //     Text("Make Recipe Public"),
                      //   ],
                      // ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (_isCreatingRecipe) return;
                          if (!_canSubmit) return;
                          setState(() {
                            _isCreatingRecipe = true;
                          });

                          late final bool? response;
                          if (_isEditing && !_isCopying) {
                            response = await _editRecipe();
                          } else {
                            response = await _createRecipe();
                          }
                          setState(() {
                            _isCreatingRecipe = false;
                          });

                          if (response == true && context.mounted) {
                            context.pop(true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canSubmit ? Colors.green : Colors.grey[600],
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          maximumSize: Size(double.infinity, 50.h),
                          minimumSize: Size(double.infinity, 50.h),
                          shadowColor: Colors.black,
                        ),
                        child:
                            _isCreatingRecipe
                                ? CircularProgressIndicator()
                                : Text(
                                  _labelText,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _createRecipe() async {
    final int? prepTime = int.tryParse(_prepTimeController.text);
    final int? cookTime = int.tryParse(_cookTimeController.text);

    if (_recipeNameController.text.isEmpty) {
      showSnackbar(context, "Recipe name cannot be empty");
      return false;
    }

    if (prepTime == null &&
            _prepTimeController.text.isNotEmpty &&
            _includeTimeEstimations ||
        prepTime != null && prepTime < 0) {
      showSnackbar(
        context,
        "Preparation time must be a valid non negative number",
      );
      return false;
    }

    if (cookTime == null &&
            _cookTimeController.text.isNotEmpty &&
            _includeTimeEstimations ||
        cookTime != null && cookTime < 0) {
      showSnackbar(context, "Cook time must be a valid non negative number");
      return false;
    }

    final name = _recipeNameController.text.trim();

    final response = await SupabaseHelper.recipe.createNewRecipe(
      _recipeImageFile,
      name,
      prepTime,
      cookTime,
      _ingredientsList,
      _instructionsList,
      _groceryList,
      _selectedGroups,

      _isPublic,
    );

    if (response.success && mounted) {
      final failedGroups = response.failedToAddGroups;
      final failedImage = response.failedToUploadImage;

      if (failedGroups != null) {
        if (failedGroups.isNotEmpty) {
          showSnackbar(context, "Failed to add recipe to groups.");
        }
      }

      if (failedImage != null) {
        if (failedImage) {
          showSnackbar(context, "Failed to upload image for recipe");
        }
      }

      showSuccessSnackbar(context, "Recipe Created Successfully");
      return true;
    } else if (!response.success && mounted) {
      final localError = response.localError;
      final errorMessage = response.errorMessage;

      if (localError != null && errorMessage != null) {
        if (localError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }

    return false;
  }

  Future<bool> _editRecipe() async {
    final int? prepTime = int.tryParse(_prepTimeController.text);
    final int? cookTime = int.tryParse(_cookTimeController.text);

    if (_recipeNameController.text.isEmpty) {
      showSnackbar(context, "Recipe name cannot be empty");
      return false;
    }

    if (prepTime == null &&
            _prepTimeController.text.isNotEmpty &&
            _includeTimeEstimations ||
        prepTime != null && prepTime < 0) {
      showSnackbar(
        context,
        "Preparation time must be a valid non negative number",
      );
      return false;
    }

    if (cookTime == null &&
            _cookTimeController.text.isNotEmpty &&
            _includeTimeEstimations ||
        cookTime != null && cookTime < 0) {
      showSnackbar(context, "Cook time must be a valid non negative number");
      return false;
    }

    final name = _recipeNameController.text.trim();

    final bool noImageBecameAnImage =
        _recipeToEditImageUrl == null && _recipeImageFile != null;
    final bool anImageBecameNoImage = _removeImage;
    final bool anImageBecameADiffImage =
        _recipeToEditImageUrl != null && _recipeImageFile != null;

    final bool changeImage =
        noImageBecameAnImage || anImageBecameADiffImage || anImageBecameNoImage;

    final response = await SupabaseHelper.recipe.updateRecipe(
      _recipeImageFile,
      _recipeToEdit!.id, // Pass the recipe ID
      name,
      prepTime,
      cookTime,
      _ingredientsList,
      _instructionsList,
      _groceryList,
      _selectedGroups,
      _isPublic,
      changeImage,
    );

    if (response.success && mounted) {
      final failedGroups = response.failedToAddGroups;
      final failedImage = response.failedToUploadImage;

      if (failedGroups != null) {
        if (failedGroups.isNotEmpty) {
          showSnackbar(context, "Failed to add recipe to groups.");
        }
      }

      if (failedImage != null) {
        if (failedImage) {
          showSnackbar(context, "Failed to upload image for recipe");
        }
      }

      showSuccessSnackbar(context, "Recipe Updated Successfully");
      return true;
    } else if (!response.success && mounted) {
      final localError = response.localError;
      final errorMessage = response.errorMessage;

      if (localError != null && errorMessage != null) {
        if (localError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }

    return false;
  }

  Future<void> _updateRecipeImage() async {
    dynamic response = await showModalBottomSheet(
      context: context,
      builder:
          (context) => TakePhotoBottomModalWidget(
            includeRemoveImage:
                _recipeImageFile != null || _recipeToEditImageUrl != null,
          ),
    );

    if (response != null) {
      if (response is File) {
        setState(() {
          _recipeImageFile = response;
          _removeImage = false;
        });
      }
      if (response is bool) {
        setState(() {
          _removeImage = response;
          _recipeImageFile = null;
        });
      }
    }
  }

  void _showHiddenFields() {
    setState(() {
      _hideGroceryItems = false;
      _hideGroups = false;
      _hideIngredients = false;
      _hideInstructions = false;
      _hideTimeEstimations = false;
    });
  }

  @override
  void dispose() {
    _groceryItemsController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _recipeNameController.dispose();
    _groupsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }
}
