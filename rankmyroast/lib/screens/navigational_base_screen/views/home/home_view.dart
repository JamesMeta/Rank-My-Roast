import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/recipe_rating.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final Future<String?> _usernameFuture;
  late final Future<List<Schedule>?> _schedulesFuture;
  late final Future<List<RecipeRating>?> _recipeRatingsFuture;

  @override
  void initState() {
    _usernameFuture = getUsername();
    _schedulesFuture = getSchedules();
    _recipeRatingsFuture = getRecipeRatings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<String?>(
            future: _usernameFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildWelcomeDisplay("User");
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data == null) {
                return _buildWelcomeDisplay("User");
              } else {
                final username = snapshot.data!;
                return _buildWelcomeDisplay(username);
              }
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Schedule>?>(
            future: _schedulesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No scheduled events found.');
              } else {
                final schedules = snapshot.data!;
                return _buildScheduledEventDisplay(
                  getNextScheduledEvent(schedules),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<RecipeRating>?>(
            future: _recipeRatingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No recipe ratings found.');
              } else {
                final recipeRatings = snapshot.data!;
                return Column(
                  children: [
                    const Text(
                      'Recipe Ratings:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeDisplay(String username) {
    return Text(
      'Welcome Back $username!',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildScheduledEventDisplay(Schedule? schedule) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (schedule != null) {
      final recipe = schedule.recipe;
      final servedAt = schedule.servedAt.substring(0, 10);
      final imageUrl = schedule.recipe.publicImageUrl;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Coming Up Next:", style: TextStyle(fontSize: 24.sp)),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(width: 2, color: Colors.grey[700]!),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child:
                      imageUrl == null
                          ? SizedBox(
                            height: 220.h,
                            child: Image.asset(
                              'assets/images/rankmyroast_icon4.png',
                              fit: BoxFit.cover,
                            ),
                          )
                          : CachedNetworkImage(
                            httpHeaders: {
                              'Authorization':
                                  'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
                            },
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            height: 220.h,
                            width: screenWidth,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 220.h,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 56,
                                  ),
                                ),
                          ),
                ),
                Positioned(
                  bottom: 40,
                  child: Container(
                    width: screenWidth - 64,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(199, 27, 78, 28),
                    ),
                    child: Column(
                      children: [
                        Text(
                          recipe.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          servedAt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Text("ddaw");
    }
  }

  //Widget _buildRecipeRatingDisplay(RecipeRating? recipeRating) {}

  Schedule? getNextScheduledEvent(List<Schedule> schedules) {
    if (schedules.isEmpty) return null;

    schedules.sort(
      (a, b) =>
          DateTime.parse(a.servedAt).compareTo(DateTime.parse(b.servedAt)),
    );
    final now = DateTime.now();

    for (final schedule in schedules) {
      if (DateTime.parse(schedule.servedAt).isAfter(now)) {
        return schedule;
      }
    }

    return null;
  }

  Future<Recipe?> getUnratedRecipeInPastEvents(
    List<Schedule> schedules,
    List<RecipeRating> recipeRatings,
  ) async {
    final ratedRecipeIds =
        recipeRatings.map((rating) => rating.recipeId).toSet();

    final recipeList =
        await SupabaseHelper.recipe.getAccessibleRecipesForUser();

    if (recipeList == null) {
      return null;
    }

    final pastSchedules = schedules.where((schedule) {
      return DateTime.parse(schedule.servedAt).isBefore(DateTime.now());
    });

    for (final schedule in pastSchedules) {
      if (!ratedRecipeIds.contains(schedule.recipe.id)) {
        final recipe =
            recipeList
                .where((recipe) => recipe.id == schedule.recipe.id)
                .firstOrNull;
        if (recipe != null) {
          return recipe;
        }
      }
    }

    return null;
  }

  Future<String?> getUsername() {
    return SupabaseHelper.users.getUsername();
  }

  Future<List<Schedule>?> getSchedules() {
    return SupabaseHelper.schedule.getAllScheduledEventsForUser();
  }

  Future<List<RecipeRating>?> getRecipeRatings() {
    return SupabaseHelper.recipe.getRatingsByUser();
  }
}
