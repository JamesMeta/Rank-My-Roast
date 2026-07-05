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
    return appointments![index].recipe.name +
        '\t\t[${appointments![index].group.name}]';
  }

  @override
  Color getColor(int index) {
    final List<Color> colors = [
      Colors.green,
      const Color.fromARGB(255, 46, 125, 50),
      const Color.fromARGB(255, 27, 70, 29),
      const Color.fromARGB(255, 181, 80, 0),
      const Color.fromARGB(255, 13, 89, 94),
      const Color.fromARGB(255, 30, 30, 30),
      const Color.fromARGB(255, 55, 71, 79),
    ];
    return colors[index % colors.length];
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}
