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
    String notes,
    DateTime servedAt,
  ) async {
    try {
      final userId = SupabaseHelper.users.getAuthId();

      final response =
          await _client
              .from("schedule")
              .insert({
                "group_id": groupId,
                "recipe_id": recipeId,
                "served_at": servedAt.toIso8601String(),
                "notes": notes,
                "user_id": userId,
              })
              .select("id")
              .single();

      if (response["id"] == null) {
        print("Error creating scheduled event");
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
    String newNotes,
  ) async {
    try {
      final response =
          await _client
              .from("schedule")
              .update({
                "served_at": newServedAt.toIso8601String(),
                "recipe_id": newRecipeId,
                "group_id": newGroupId,
                "notes": newNotes,
              })
              .eq("id", scheduleId)
              .select(); // <--- Forces Supabase to return the modified row(s)

      // If the list is empty, no row matched the ID or RLS denied it
      if (response == null || (response as List).isEmpty) {
        print(
          "Update executed but 0 rows were altered. Check your ID or RLS policies.",
        );
        return false;
      }

      return true;
    } catch (e) {
      print("Error unable to update scheduled event: $e");
      return null;
    }
  }
}
