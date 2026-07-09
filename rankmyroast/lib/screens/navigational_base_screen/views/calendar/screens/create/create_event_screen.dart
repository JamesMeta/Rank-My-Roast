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

  @override
  void initState() {
    if (widget.extra != null) {
      _labelText = "Edit Event";
      _eventToEdit = widget.extra!.event;
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
                //TODO
                // DELETE EVENT CODE
              },
              icon: Icon(Icons.delete, color: Colors.white),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey[600]!, width: 1.5),
              ),
              child:
                  _imageUrl == null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 200,
                          child: Image.asset(
                            'assets/images/rankmyroast_icon4.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      : CachedNetworkImage(
                        httpHeaders: {
                          'Authorization':
                              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
                        },
                        imageUrl: _imageUrl!,
                        fit: BoxFit.fill,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 56),
                            ),
                      ),
            ),

            FutureBuilder(
              future: _groupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No groups found.'));
                } else {
                  final groups = snapshot.data!;
                  return Column(
                    children: [
                      DropdownButtonFormField<Group>(
                        decoration: InputDecoration(
                          labelText: 'Select Group',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            groups.map((group) {
                              return DropdownMenuItem<Group>(
                                value: group,
                                child: Text(group.name),
                              );
                            }).toList(),
                        onChanged: (Group? selectedGroup) {
                          setState(() {
                            _selectedGroup = selectedGroup;
                            _recipesFuture = _getRecipes(selectedGroup!.id);
                          });
                        },
                      ),

                      if (_recipesFuture != null) ...[
                        SizedBox(height: 16),
                        FutureBuilder<List<Recipe>?>(
                          future: _recipesFuture,
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
                            } else {
                              final recipes = snapshot.data ?? [];
                              return TextField(
                                decoration: InputDecoration(
                                  labelText: 'Select Recipe',
                                  border: OutlineInputBorder(),
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
                                      _selectedRecipe = selectedRecipe;
                                      _imageUrl = selectedRecipe.publicImageUrl;
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

                      SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () => _selectDate(context),
                      ),

                      SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),

                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Handle event creation or editing logic here
                        },
                        child: Text(_labelText),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
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

  @override
  void dispose() {
    super.dispose();
    _notesController.dispose();
    _dateController.dispose();
  }
}
