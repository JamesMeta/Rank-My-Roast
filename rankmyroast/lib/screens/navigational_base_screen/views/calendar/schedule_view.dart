import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/calendar/classes/event_data_source.dart';
import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late Future<List<Schedule>?> _scheduledEvents;
  CalendarView _selectedView =
      CalendarView.schedule; // Default to the first view (day view)

  @override
  void initState() {
    super.initState();

    _scheduledEvents = _getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(height: 16),
          Expanded(
            child: FutureBuilder(
              future: _scheduledEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No scheduled events.'));
                } else {
                  final events = snapshot.data!;
                  return SfCalendar(
                    view: _selectedView,
                    dataSource: EventDataSource(events),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Schedule>?> _getEvents() async {
    return await SupabaseHelper.schedule.getAllScheduledEventsForUser();
  }
}
