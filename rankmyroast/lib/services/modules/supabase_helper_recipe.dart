import 'dart:io';

import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/recipe_rating.dart';
import 'package:rankmyroast/classes/responses/create_recipe_response.dart';
import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseHelperRecipe {
  static final _client = Supabase.instance.client;

  Future<CreateRecipeResponse> createNewRecipe(
    File? image,
    String name,
    int? prepTime,
    int? cookTime,
    List<String>? ingredientList,
    List<String>? instructionList,
    List<String>? groceryList,
    List<Group> groupList,
    bool? isPublic,
  ) async {
    try {
      final insert =
          image == null
              ? {
                "name": name,
                "ingredients": ingredientList,
                "instructions": instructionList,
                "groceries": groceryList,
                "prep_time": prepTime,
                "cook_time": cookTime,
                "is_public": isPublic,
                "image_name": null,
              }
              : {
                "name": name,
                "ingredients": ingredientList,
                "instructions": instructionList,
                "groceries": groceryList,
                "prep_time": prepTime,
                "cook_time": cookTime,
                "is_public": isPublic,
              };

      final response =
          await _client.from("recipe").insert(insert).select("*").single();

      final recipeId = response["id"];
      final imageName = response["image_name"];

      final success = true;

      final List<Map<String, dynamic>> groupLinks =
          groupList
              .map((g) => {"recipe_id": recipeId, "group_id": g.id})
              .toList();

      final failedGroups = <Group>[];

      try {
        await _client.from("recipe_group").insert(groupLinks);
      } catch (e) {
        failedGroups.addAll(groupList);
      }

      bool imageUploadFailed = true;
      if (image != null) {
        final imageResponse = await SupabaseHelper.storage.uploadFileToBucket(
          bucketName: "public_recipe_image",
          file: image,
          fileName: imageName,
        );

        if (imageResponse != null) imageUploadFailed = false;
      } else {
        imageUploadFailed = false;
      }
      return CreateRecipeResponse(
        success: success,
        failedToAddGroups: failedGroups,
        failedToUploadImage: imageUploadFailed,
      );
    } catch (e) {
      return CreateRecipeResponse(
        success: false,
        localError: false,
        errorMessage: e.toString(),
      );
    }
  }

  String generateUUID() {
    final uuid = Uuid();

    return uuid.v4();
  }

  Future<CreateRecipeResponse> updateRecipe(
    File? image,
    String recipeId,
    String name,
    int? prepTime,
    int? cookTime,
    List<String>? ingredientList,
    List<String>? instructionList,
    List<String>? groceryList,
    List<Group> groupList,

    bool? isPublic,
    bool changeImage,
  ) async {
    try {
      final newImageName = image != null ? generateUUID() : null;

      final update =
          changeImage
              ? image == null
                  ? {
                    "name": name,
                    "ingredients": ingredientList,
                    "instructions": instructionList,
                    "groceries": groceryList,
                    "prep_time": prepTime,
                    "cook_time": cookTime,
                    "is_public": isPublic,
                    "image_name": null,
                  }
                  : {
                    "name": name,
                    "ingredients": ingredientList,
                    "instructions": instructionList,
                    "groceries": groceryList,
                    "prep_time": prepTime,
                    "cook_time": cookTime,
                    "is_public": isPublic,
                    "image_name": newImageName,
                  }
              : {
                "name": name,
                "ingredients": ingredientList,
                "instructions": instructionList,
                "groceries": groceryList,
                "prep_time": prepTime,
                "cook_time": cookTime,
                "is_public": isPublic,
              };

      final response =
          await _client
              .from("recipe")
              .update(update)
              .eq("id", recipeId)
              .select("*")
              .single();

      recipeId = response["id"];
      final imageName = response["image_name"];

      // The one in the trillion chance that the UUID generated for the image name already exists, we want to prevent the recipe from being updated with an image name that doesn't match the one in storage
      if (imageName != newImageName && changeImage && image != null) {
        return CreateRecipeResponse(
          success: false,
          localError: true,
          errorMessage:
              "Error: Recipe failed to be updated at this time, please try again later.",
        );
      }

      final success = true;

      await _client.from("recipe_group").delete().eq("recipe_id", recipeId);

      final List<Map<String, dynamic>> groupLinks =
          groupList
              .map((g) => {"recipe_id": recipeId, "group_id": g.id})
              .toList();

      final failedGroups = <Group>[];

      try {
        await _client.from("recipe_group").insert(groupLinks);
      } catch (e) {
        failedGroups.addAll(groupList);
      }

      bool imageUploadFailed = false;
      if (image != null) {
        final imageResponse = await SupabaseHelper.storage.uploadFileToBucket(
          bucketName: "public_recipe_image",
          file: image,
          fileName: imageName,
        );

        if (imageResponse == null) imageUploadFailed = true;
      }
      return CreateRecipeResponse(
        success: success,
        failedToAddGroups: failedGroups,
        failedToUploadImage: imageUploadFailed,
      );
    } catch (e) {
      return CreateRecipeResponse(
        success: false,
        localError: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<List<Group>?> getGroupsForRecipe(String recipeId) async {
    try {
      final response = await _client
          .from("recipe_group")
          .select(
            "group_id, group (id, created_at, name, user_id, grade_visible, use_rating, is_personal_group)",
          )
          .eq("recipe_id", recipeId);

      if (response.isNotEmpty) {
        final groups =
            (response as List)
                .map(
                  (item) =>
                      Group.fromMap(item['group'] as Map<String, dynamic>),
                )
                .toList();
        return groups;
      }
    } catch (e) {
      print('Error fetching groups for recipe: $e');
    }
    return null;
  }

  Future<List<Recipe>?> getRecipesByGroupId(String groupId) async {
    try {
      final response = await _client
          .from("recipe_group")
          .select(
            "recipe_id, recipe (id, created_at, name, ingredients, instructions, groceries, prep_time, cook_time, is_public, image_name)",
          )
          .eq("group_id", groupId);

      if (response.isNotEmpty) {
        final recipes =
            (response as List)
                .map(
                  (item) =>
                      Recipe.fromMap(item['recipe'] as Map<String, dynamic>),
                )
                .toList();
        return recipes;
      }
    } catch (e) {
      print('Error fetching recipes by group id: $e');
    }
    return null;
  }

  Future<List<RecipeRating>?> getRatingsByRecipeIdByGroupId(
    String recipeId,
    String groupId,
  ) async {
    try {
      final response = await _client
          .from("recipe_rating")
          .select("*")
          .eq("recipe_id", recipeId)
          .eq("group_id", groupId);

      if (response.isNotEmpty) {
        final ratings =
            (response as List)
                .map(
                  (item) => RecipeRating.fromMap(item as Map<String, dynamic>),
                )
                .toList();
        return ratings;
      }
    } catch (e) {
      print('Error fetching ratings for recipe by group id: $e');
    }
    return null;
  }

  Future<List<RecipeRating>?> getRatingsByGroupId(String groupId) async {
    try {
      final response = await _client
          .from("recipe_rating")
          .select("*")
          .eq("group_id", groupId);

      if (response.isNotEmpty) {
        final ratings =
            (response as List)
                .map(
                  (item) => RecipeRating.fromMap(item as Map<String, dynamic>),
                )
                .toList();
        return ratings;
      }
    } catch (e) {
      print('Error fetching ratings for recipe by group id: $e');
    }
    return null;
  }

  //TODO
  //this can be optimized by doing an upsert with the full list of ratings instead of separating into creates and updates, but supabase upsert doesn't work with RLS policies that would allow users to only update their own ratings, so for now we will do separate create and update requests
  Future<bool?> updateRecipeRanking(List<RecipeRating> newRankings) async {
    try {
      final newItems = <Map<String, dynamic>>[];
      final existingItems = <Map<String, dynamic>>[];

      for (var ranking in newRankings) {
        if (ranking.id == null) {
          newItems.add({
            "rating": ranking.rating,
            "ranking": ranking.ranking,
            "recipe_id": ranking.recipeId,
            "user_id": ranking.userId,
            "group_id": ranking.groupId,
          });
        } else {
          existingItems.add({
            "id": ranking.id,
            "rating": ranking.rating,
            "ranking": ranking.ranking,
            // Omit user_id, group_id, and recipe_id so RLS UPDATE rules don't trip
          });
        }
      }

      // Execute at most 2 network requests instead of a loop of N requests
      if (newItems.isNotEmpty) {
        await _client.from("recipe_rating").insert(newItems);
      }

      if (existingItems.isNotEmpty) {
        final updateFutures = existingItems.map((item) {
          final id = item['id'];
          return _client.from("recipe_rating").update(item).eq("id", id);
        });

        await Future.wait(updateFutures);
      }

      return true;
    } catch (e) {
      print('Error updating Recipe Ratings $e');
    }
    return null;
  }

  Future<bool?> upsertRecipeRating(
    Recipe recipe,
    Group? group,
    int rating,
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      if (group == null) {
        // Check if a rating already exists for this user and recipe without a group
        final existingRatingResponse =
            await _client
                .from("recipe_rating")
                .select("*")
                .eq("recipe_id", recipe.id)
                .eq("user_id", userId)
                .single();

        if (existingRatingResponse.isEmpty) {
          // No existing rating, create a new one
          final response =
              await _client
                  .from("recipe_rating")
                  .insert({
                    "rating": rating,
                    "recipe_id": recipe.id,
                    "user_id": userId,
                    "group_id": null,
                  })
                  .select("*")
                  .single();

          if (response["rating"] == rating) {
            return true;
          } else {
            return false;
          }
        }
        // Existing rating found, update it
        final response =
            await _client
                .from("recipe_rating")
                .update({"rating": rating})
                .eq("id", existingRatingResponse["id"])
                .select("*")
                .single();

        if (response["rating"] == rating) {
          return true;
        } else {
          return false;
        }
      } else {
        // Check if a rating already exists for this user, recipe, and group
        final existingRatingResponse =
            await _client
                .from("recipe_rating")
                .select("*")
                .eq("recipe_id", recipe.id)
                .eq("user_id", userId)
                .eq("group_id", group.id)
                .single();
        if (existingRatingResponse.isEmpty) {
          // No existing rating, create a new one
          final response =
              await _client
                  .from("recipe_rating")
                  .insert({
                    "rating": rating,
                    "recipe_id": recipe.id,
                    "user_id": userId,
                    "group_id": group.id,
                  })
                  .select("*")
                  .single();
          if (response["rating"] == rating) {
            return true;
          } else {
            return false;
          }
        }
        // Existing rating found, update it

        final response =
            await _client
                .from("recipe_rating")
                .update({"rating": rating})
                .eq("id", existingRatingResponse["id"])
                .select("*")
                .single();

        if (response["rating"] == rating) {
          return true;
        } else {
          return false;
        }
      }
    } on Exception catch (e) {
      print('Error upserting recipe rating: $e');
      return null;
    }
  }

  Future<List<RecipeRating>?> getRatingsByUser() async {
    try {
      final userId = SupabaseHelper.users.getAuthId();
      final response = await _client
          .from("recipe_rating")
          .select("*")
          .eq("user_id", userId!);

      return response.map((r) => RecipeRating.fromMap(r)).toList();
    } catch (e) {
      print('Error fetching recipe ratings: $e');
      return null;
    }
  }

  // Supabase RLS Polcies prevent users from accessing recipes that aren't in their groups
  // so doing a select all on the recipes table will not return any recipes that the user doesn't have access to,
  // we can just do a select all and return the results
  // JM1 14/JUL/2026
  Future<List<Recipe>?> getAccessibleRecipesForUser() async {
    try {
      final response = await _client.from("recipe").select("*");

      return response.map((r) => Recipe.fromMap(r)).toList();
    } catch (e) {
      print('Error fetching accessible recipes for user: $e');
      return null;
    }
  }
}
