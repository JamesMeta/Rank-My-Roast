import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/extra/rank_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/recipe_rating.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/calendar/widgets/view_event_dialog_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/viewer/widgets/rating_dialog_widget.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String?>(
              future: _usernameFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildWelcomeDisplay('there', isLoading: true);
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return _buildWelcomeDisplay(
                    'there',
                    message: 'We could not load your profile right now.',
                  );
                } else {
                  final username = snapshot.data!;
                  return _buildWelcomeDisplay(username);
                }
              },
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Schedule>?>(
              future: _schedulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonCard(
                    title: 'Upcoming event',
                    icon: Icons.event_available,
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return _buildEmptyStateCard(
                    title: 'Upcoming event',
                    message: 'We could not load your schedule right now.',
                    icon: Icons.event_busy,
                  );
                } else {
                  final schedules = snapshot.data!;
                  return _buildScheduledEventDisplay(
                    getNextScheduledEvent(schedules),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            FutureBuilder<(Recipe, Group, String)?>(
              future: Future.wait([
                _schedulesFuture,
                _recipeRatingsFuture,
              ]).then((results) async {
                final recipeRatings =
                    (results[1] as List<RecipeRating>?) ?? <RecipeRating>[];
                final schedules =
                    (results[0] as List<Schedule>?) ?? <Schedule>[];

                return await getUnratedRecipeInPastEvents(
                  schedules,
                  recipeRatings,
                );
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonCard(
                    title: 'Quick ranking',
                    icon: Icons.rate_review,
                  );
                } else if (snapshot.hasError) {
                  return _buildEmptyStateCard(
                    title: 'Quick ranking',
                    message: 'We could not load your recent meals right now.',
                    icon: Icons.rate_review,
                  );
                } else {
                  final recipe = snapshot.data?.$1;
                  final group = snapshot.data?.$2;
                  final servedAt = snapshot.data?.$3.substring(0, 10);

                  return _buildRecipeRatingDisplay(recipe, group, servedAt);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeDisplay(
    String username, {
    bool isLoading = false,
    String? message,
  }) {
    final displayName = username.trim().isEmpty ? 'there' : username;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green accent header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isLoading ? 'Welcome back' : 'Welcome back, $displayName!',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.grey[400],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message ??
                        (isLoading
                            ? 'Loading your home overview...'
                            : 'Use this page to check your next meal or leave a quick rating.'),
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required String title, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Skeleton body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                _buildPlaceholderBox(
                  height: 180.h,
                  width: double.infinity,
                  borderRadius: 14,
                ),
                const SizedBox(height: 14),
                // Title placeholder
                _buildPlaceholderBox(height: 16, width: 160, borderRadius: 8),
                const SizedBox(height: 10),
                // Subtitle placeholder
                _buildPlaceholderBox(height: 12, width: 100, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBox({
    required double height,
    required double width,
    double borderRadius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Empty state body
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.grey[400], size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledEventDisplay(Schedule? schedule) {
    final recipe = schedule?.recipe;
    final servedAt = schedule?.servedAt.substring(0, 10);
    final imageUrl = schedule?.recipe.publicImageUrl;

    if (schedule == null || recipe == null) {
      return _buildEmptyStateCard(
        title: 'Upcoming event',
        message: 'No upcoming events are on the calendar right now.',
        icon: Icons.event,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming event',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tap to view the details',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      () => showDialog(
                        context: context,
                        builder:
                            (context) => ViewEventDialogWidget(event: schedule),
                      ),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          // Content
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ViewEventDialogWidget(event: schedule),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child:
                        imageUrl == null
                            ? SizedBox(
                              height: 180.h,
                              width: double.infinity,
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
                              height: 180.h,
                              width: double.infinity,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 180.h,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 56,
                                    ),
                                  ),
                            ),
                  ),
                  const SizedBox(height: 14),
                  // Recipe info row
                  _buildInfoRow(
                    icon: Icons.restaurant_menu,
                    label: recipe.name,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: servedAt ?? '',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeRatingDisplay(
    Recipe? recipe,
    Group? group,
    String? servedAt,
  ) {
    if (recipe == null) {
      return _buildEmptyStateCard(
        title: 'Quick ranking',
        message: 'All recent meals have already been ranked.',
        icon: Icons.rate_review,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.rate_review, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick ranking',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tap to leave a rating',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (group?.useRating == true) {
                      showDialog(
                        context: context,
                        builder:
                            (context) => RatingDialogWidget(
                              recipe: recipe,
                              group: group,
                              pastRating: null,
                            ),
                      );
                    } else {
                      context.push(
                        "/base/rank-recipe",
                        extra: RankRecipeExtra(
                          ratings: null,
                          recipeToRank: recipe,
                          group: group,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          // Content
          GestureDetector(
            onTap: () async {
              if (group?.useRating == true) {
                await showDialog(
                  context: context,
                  builder:
                      (context) => RatingDialogWidget(
                        recipe: recipe,
                        group: group,
                        pastRating: null,
                      ),
                );
              } else {
                await context.push(
                  "/base/rank-recipe",
                  extra: RankRecipeExtra(
                    ratings: null,
                    recipeToRank: recipe,
                    group: group,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child:
                        recipe.publicImageUrl == null
                            ? SizedBox(
                              height: 180.h,
                              width: double.infinity,
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
                              imageUrl: recipe.publicImageUrl!,
                              fit: BoxFit.cover,
                              height: 180.h,
                              width: double.infinity,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 180.h,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 56,
                                    ),
                                  ),
                            ),
                  ),
                  const SizedBox(height: 14),
                  // Recipe info rows
                  _buildInfoRow(
                    icon: Icons.restaurant_menu,
                    label: recipe.name,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: servedAt ?? '',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15.sp : 13.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isBold ? Colors.grey[800] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

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

  Future<(Recipe, Group, String)?> getUnratedRecipeInPastEvents(
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
          return (recipe, schedule.group, schedule.servedAt);
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
