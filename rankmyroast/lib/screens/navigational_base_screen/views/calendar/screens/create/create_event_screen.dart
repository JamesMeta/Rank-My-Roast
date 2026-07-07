import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rankmyroast/classes/extra/create_event_extra.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';

class CreateEventScreen extends StatefulWidget {
  final CreateEventExtra? extra;

  const CreateEventScreen({super.key, required this.extra});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final String _labelText;
  late final Schedule? _eventToEdit;

  @override
  void initState() {
    if (widget.extra != null) {
      _labelText = "Edit Event";
      _eventToEdit = widget.extra!.event;
    } else {
      _labelText = "Create Event";
      _eventToEdit = null;
    }

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
    );
  }
}
