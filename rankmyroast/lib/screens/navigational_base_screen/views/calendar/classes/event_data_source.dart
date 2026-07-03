import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Schedule> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return DateTime.parse(appointments![index].servedAt);
  }

  @override
  DateTime getEndTime(int index) {
    return DateTime.parse(
      appointments![index].servedAt,
    ).add(const Duration(hours: 1));
  }

  @override
  String getSubject(int index) {
    return appointments![index].recipe.name;
  }

  @override
  Color getColor(int index) {
    final List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}
