import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rankmyroast/classes/extra/create_event_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

class CreateEventScreen extends StatefulWidget {
  final CreateEventExtra? extra;

  const CreateEventScreen({super.key, required this.extra});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final String _labelText;
  late final Schedule? _eventToEdit;

  final DateTime? _selectedDate = null;
  final Recipe? _selectedRecipe = null;
  final Group? _selectedGroup = null;

  Future<List<Recipe>>? _recipesFuture;
  late final Future<List<Group>?> _groupsFuture;

  final TextEditingController _notesController = TextEditingController();

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
      body: Padding(padding: EdgeInsets.all(8), child: Column(children: [])),
    );
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
  }
}
