import 'package:rankmyroast/classes/modals/group_member.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';

class Group {
  final String id;
  final String createdAt;
  final String name;
  final String userId;
  final bool gradeVisible;
  final bool useRating;
  final bool isPersonalGroup;
  final List<GroupMember> groupMembers;
  List<Recipe> recipes;

  Group({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.gradeVisible,
    required this.useRating,
    required this.isPersonalGroup,
    required this.userId,
    required this.groupMembers,
    required this.recipes,
  });

  void filterDuplicateMembers() {
    final uniqueMembers = <String>{};
    groupMembers.retainWhere((member) => uniqueMembers.add(member.username));
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      createdAt: map['created_at'] ?? '',
      name: map['name'] ?? '',
      userId: map['user_id'] ?? '',
      gradeVisible: map['grade_visible'] ?? false,
      useRating: map['use_rating'] ?? false,
      isPersonalGroup: map['is_personal_group'] ?? false,
      // Mapping the JSON arrays to List of Objects
      groupMembers:
          (map['group_members'] as List? ?? [])
              .map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
              .toList(),
      recipes:
          (map['recipes'] as List? ?? [])
              .map((r) => Recipe.fromMap(r as Map<String, dynamic>))
              .toList(),
    );
  }
}
