import 'package:rankmyroast/classes/modals/recipe.dart';

class Schedule {
  int? id;
  String createdAt;
  String servedAt;
  String groupId;
  String userId;

  Recipe recipe;

  Schedule({
    this.id,
    required this.createdAt,
    required this.servedAt,
    required this.recipe,
    required this.groupId,
    required this.userId,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      createdAt: map['created_at'] ?? '',
      servedAt: map['served_at'] ?? '',
      recipe: Recipe.fromMap(map['recipe']),
      groupId: map['group_id'] ?? '',
      userId: map['user_id'] ?? '',
    );
  }
}
