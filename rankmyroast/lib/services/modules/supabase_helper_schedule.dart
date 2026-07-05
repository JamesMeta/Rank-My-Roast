import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelperSchedule {
  static final _client = Supabase.instance.client;

  Future<List<Schedule>?> getAllScheduledEventsForUser() async {
    try {
      final response = await _client
          .from("schedule")
          .select(
            "*, recipe (id, created_at, name, ingredients, instructions, groceries, prep_time, cook_time, is_public, image_name), group (id, created_at, name, user_id, grade_visible, use_rating, is_personal_group)",
          );

      return response.map((toElement) => Schedule.fromMap(toElement)).toList();
    } on Exception catch (e) {
      print("Error unable to get events for user: $e");
      return null;
    }
  }

  Future<bool?> createScheduledEvent(
    String groupId,
    String recipeId,
    DateTime servedAt,
  ) async {
    try {
      final userId = SupabaseHelper.users.getAuthId();

      final response = await _client.from("schedule").insert({
        "group_id": groupId,
        "recipe_id": recipeId,
        "served_at": servedAt.toIso8601String(),
        "user_id": userId,
      });

      if (response.error != null) {
        print("Error creating scheduled event: ${response.error!.message}");
        return false;
      }

      return true;
    } on Exception catch (e) {
      print("Error unable to create scheduled event: $e");
      return null;
    }
  }

  Future<bool?> deleteScheduledEvent(int scheduleId) async {
    try {
      final response = await _client
          .from("schedule")
          .delete()
          .eq("id", scheduleId);

      if (response.error != null) {
        print("Error deleting scheduled event: ${response.error!.message}");
        return false;
      }

      return true;
    } on Exception catch (e) {
      print("Error unable to delete scheduled event: $e");
      return null;
    }
  }

  Future<bool?> updateScheduledEvent(
    int scheduleId,
    DateTime newServedAt,
    String newRecipeId,
    String newGroupId,
  ) async {
    try {
      final response = await _client
          .from("schedule")
          .update({
            "served_at": newServedAt.toIso8601String(),
            "recipe_id": newRecipeId,
            "group_id": newGroupId,
          })
          .eq("id", scheduleId);

      if (response.error != null) {
        print("Error updating scheduled event: ${response.error!.message}");
        return false;
      }

      return true;
    } on Exception catch (e) {
      print("Error unable to update scheduled event: $e");
      return null;
    }
  }
}
