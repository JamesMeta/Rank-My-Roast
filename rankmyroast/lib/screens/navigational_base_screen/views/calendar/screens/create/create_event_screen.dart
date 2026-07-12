import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/extra/create_event_extra.dart';
import 'package:rankmyroast/classes/extra/select_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';

import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateEventScreen extends StatefulWidget {
  final CreateEventExtra? extra;

  const CreateEventScreen({super.key, required this.extra});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final String _labelText;
  late final Schedule? _eventToEdit;

  DateTime? _selectedDate;
  Recipe? _selectedRecipe;
  Group? _selectedGroup;
  String? _imageUrl;

  Future<List<Recipe>?>? _recipesFuture;
  late final Future<List<Group>?> _groupsFuture;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    if (widget.extra != null) {
      _labelText = "Edit Event";
      _eventToEdit = widget.extra!.event;
      _dateController.text = _eventToEdit!.servedAt
          .split(' ')[0]
          .substring(0, 10);
      _notesController.text = _eventToEdit.notes ?? '';
      _selectedRecipe = _eventToEdit.recipe;
      _selectedGroup = _eventToEdit.group;
      _imageUrl = _selectedRecipe?.publicImageUrl;
      _selectedDate = DateTime.parse(_eventToEdit.servedAt).toLocal();
      _recipesFuture = _getRecipes(_selectedGroup!.id);
    } else {
      _labelText = "Create Event";
      _eventToEdit = null;
    }
    _groupsFuture = _getGroups();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.green,
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
          if (_eventToEdit != null) ...[
            IconButton(
              onPressed: () async {
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: const Text(
                          'Are you sure you want to delete this event?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => context.pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirmDelete == true) {
                  final success = await _deleteScheduledEvent(
                    _eventToEdit!.id!,
                  ); // Assuming id is non-nullable

                  if (success == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event deleted successfully!'),
                      ),
                    );
                    context.pop(true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to delete event. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.delete, color: Colors.white),
            ),
          ],
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10.w),
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
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Event Details",
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          _imageUrl == null
                              ? SizedBox(
                                height: 220.h,
                                child: Image.asset(
                                  'assets/images/rankmyroast_icon4.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                              : CachedNetworkImage(
                                httpHeaders: {
                                  'Authorization':
                                      'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
                                },
                                imageUrl: _imageUrl!,
                                fit: BoxFit.cover,
                                height: 220.h,
                                width: double.infinity,
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      height: 220.h,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 56,
                                      ),
                                    ),
                              ),
                    ),

                    SizedBox(height: 20.h),
                    FutureBuilder<List<Group>?>(
                      future: _groupsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No groups found.'));
                        } else {
                          final groups = snapshot.data!;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Choose a group and recipe',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                DropdownButtonFormField<String>(
                                  value: _selectedGroup?.id,
                                  decoration: InputDecoration(
                                    labelText: 'Select Group',
                                    labelStyle: TextStyle(fontSize: 16.sp),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                  items:
                                      groups.map((group) {
                                        return DropdownMenuItem<String>(
                                          value: group.id,
                                          child: Text(
                                            group.name,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? selectedGroupId) {
                                    setState(() {
                                      _selectedGroup = groups.firstWhere(
                                        (group) => group.id == selectedGroupId,
                                      );
                                      _selectedRecipe = null;
                                      _imageUrl = null;
                                      _recipesFuture = _getRecipes(
                                        selectedGroupId!,
                                      );
                                    });
                                  },
                                ),

                                if (_recipesFuture != null) ...[
                                  SizedBox(height: 14.h),
                                  FutureBuilder<List<Recipe>?>(
                                    future: _recipesFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return TextFormField(
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            labelText: 'Loading Recipes...',
                                            labelStyle: TextStyle(
                                              fontSize: 16.sp,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.black,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 14.h,
                                                ),
                                            suffixIcon: Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                          ),
                                        );
                                      } else {
                                        final recipes = snapshot.data ?? [];
                                        return TextFormField(
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            labelText: 'Select Recipe',
                                            labelStyle: TextStyle(
                                              fontSize: 16.sp,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.black,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 14.h,
                                                ),
                                            suffixIcon: Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                          ),
                                          onTap: () async {
                                            final selectedRecipe =
                                                await context.push(
                                                      "/base/create-event/select-recipe",
                                                      extra: SelectRecipeExtra(
                                                        recipes: recipes,
                                                      ),
                                                    )
                                                    as Recipe?;

                                            if (selectedRecipe != null) {
                                              setState(() {
                                                _selectedRecipe =
                                                    selectedRecipe;
                                                _imageUrl =
                                                    selectedRecipe
                                                        .publicImageUrl;
                                              });
                                            }
                                          },
                                          controller: TextEditingController(
                                            text: _selectedRecipe?.name ?? '',
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                      },
                    ),

                    SizedBox(height: 20.h),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Event Information',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              labelStyle: TextStyle(fontSize: 16.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                            onTap: () => _selectDate(context),
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              labelStyle: TextStyle(fontSize: 16.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () async {
                        if (_isLoading) return; // Prevent multiple submissions

                        setState(() {
                          _isLoading = true;
                        });
                        final bool success = await _handleSubmit();
                        setState(() {
                          _isLoading = false;
                        });

                        if (success) {
                          context.pop(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.black),
                        ),
                        minimumSize: Size(double.infinity, 52.h),
                      ),
                      child:
                          !_isLoading
                              ? Text(
                                _labelText,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                              : const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
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
    );
  }

  Future<bool> _handleSubmit() async {
    if (_selectedGroup == null ||
        _selectedRecipe == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a group, recipe, and date.')),
      );
      return false;
    }

    final servedAt = _selectedDate!;
    final groupId = _selectedGroup!.id;
    final recipeId = _selectedRecipe!.id;

    bool? success;
    if (_eventToEdit != null) {
      // Update existing event
      final id = _eventToEdit.id!;
      success = await _updateScheduledEvent(
        id,
        servedAt,
        recipeId,
        groupId,
        _notesController.text,
      );
    } else {
      // Create new event
      success = await _createScheduledEvent(
        groupId,
        recipeId,
        _notesController.text,
        servedAt,
      );
    }

    if (success == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Event saved successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event. Please try again.')),
      );
    }
    return success == true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000), // Earliest allowable date
      lastDate: DateTime(2101), // Latest allowable date
    );

    // If the user didn't cancel, update the state
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.toLocal()}".split(' ')[0]; // Format the date as needed
      });
    }
  }

  Future<List<Group>?> _getGroups() {
    return SupabaseHelper.groups.getGroupsForUser();
  }

  Future<List<Recipe>?> _getRecipes(final String groupId) {
    return SupabaseHelper.recipe.getRecipesByGroupId(groupId);
  }

  Future<bool?> _createScheduledEvent(
    String groupId,
    String recipeId,
    String notes,
    DateTime servedAt,
  ) async {
    return SupabaseHelper.schedule.createScheduledEvent(
      groupId,
      recipeId,
      notes,
      servedAt,
    );
  }

  Future<bool?> _updateScheduledEvent(
    int scheduleId,
    DateTime newServedAt,
    String newRecipeId,
    String newGroupId,
    String newNotes,
  ) async {
    return SupabaseHelper.schedule.updateScheduledEvent(
      scheduleId,
      newServedAt,
      newRecipeId,
      newGroupId,
      newNotes,
    );
  }

  Future<bool?> _deleteScheduledEvent(int scheduleId) async {
    return SupabaseHelper.schedule.deleteScheduledEvent(scheduleId);
  }

  @override
  void dispose() {
    super.dispose();
    _notesController.dispose();
    _dateController.dispose();
  }
}
