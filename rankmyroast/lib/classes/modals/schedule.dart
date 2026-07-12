import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';

class Schedule {
  final int? id;
  final String createdAt;
  final String servedAt;
  final String userId;
  final String? notes;

  final Recipe recipe;
  final Group group;

  Schedule({
    this.id,
    required this.createdAt,
    required this.servedAt,
    required this.recipe,
    required this.group,
    required this.userId,
    this.notes,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      createdAt: map['created_at'] ?? '',
      servedAt: map['served_at'] ?? '',
      recipe: Recipe.fromMap(map['recipe']),
      group: Group.fromMap(map['group']),
      userId: map['user_id'] ?? '',
      notes: map['notes'],
    );
  }
}
