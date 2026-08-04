//
// My apologies to my future self the ranking system is a complete mess
//

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/mixin/snackbar_service.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/recipe_rating.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/rank/classes/recipe_group_user_ranking.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/rank/widgets/widgets/recipe_list_tile_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/rank/widgets/recipe_reorderable_list_tile_widget.dart';
import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankRecipeScreen extends StatefulWidget {
  final List<RecipeRating>? ratings;
  final Group? group;
  final Recipe? recipeToRank;

  const RankRecipeScreen({
    super.key,
    this.ratings,
    this.group,
    this.recipeToRank,
  });

  @override
  State<RankRecipeScreen> createState() => _RankRecipeScreenState();
}

class _RankRecipeScreenState extends State<RankRecipeScreen>
    with SnackbarService {
  late final Future<List<RecipeGroupUserRanking>> _recipeGroupUserRankingList;
  final List<RecipeGroupUserRanking> _poppedGroupUserRanking = [];
  List<RecipeRating>? _ratings;
  Group? _group;
  Recipe? _recipeToRank;

  bool _viewGroupRankings = false;
  bool _modifyRecipeRankings = false;
  bool _reordering = false;
  bool _isSubmitting = false;

  final List<String> _titles = [
    'Your Rankings',
    'Group Rankings',
    'Edit Group Rankings',
  ];

  final List<Color> _colors = [
    Colors.green,
    const Color.fromARGB(255, 37, 87, 39),

    const Color.fromARGB(255, 102, 199, 105),
  ];

  int _currentTitleIndex = 0;

  @override
  void initState() {
    _ratings = widget.ratings;
    _group = widget.group;
    _recipeToRank = widget.recipeToRank;
    _recipeGroupUserRankingList = _fetchRecipeGroupUserRankings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _colors[_currentTitleIndex],
          centerTitle: true,
          title: Text(
            _titles[_currentTitleIndex],
            style: TextStyle(fontSize: 28.sp),
          ),
          foregroundColor: Colors.white,
          actions:
              _group != null
                  ? [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_viewGroupRankings) {
                            _currentTitleIndex = 0;
                          } else {
                            _currentTitleIndex = 1;
                            _modifyRecipeRankings = false;
                          }
                          _viewGroupRankings = !_viewGroupRankings;
                          _reordering = false;
                        });
                      },
                      icon: Icon(
                        _viewGroupRankings ? Icons.person : Icons.group,
                      ),
                    ),
                    if (!_viewGroupRankings)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_modifyRecipeRankings) {
                              _currentTitleIndex = 0;
                            } else {
                              _currentTitleIndex = 2;
                            }
                            _modifyRecipeRankings = !_modifyRecipeRankings;
                            _reordering = !_reordering;
                          });
                        },
                        icon: Icon(
                          _modifyRecipeRankings ? Icons.edit_off : Icons.edit,
                        ),
                      ),
                  ]
                  : null,
        ),

        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder(
                future: _recipeGroupUserRankingList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No recipes found.'));
                  } else {
                    final List<RecipeGroupUserRanking>
                    recipeGroupUserRankingList = snapshot.data!;

                    removeValueFromList(Recipe recipe) {
                      final recipeRating = recipeGroupUserRankingList
                          .singleWhere(
                            (recipeRating) =>
                                recipeRating.recipe.id == recipe.id,
                          );

                      setState(() {
                        recipeGroupUserRankingList.remove(recipeRating);
                      });
                      _poppedGroupUserRanking.add(recipeRating);
                    }

                    if (!_reordering) {
                      if (_poppedGroupUserRanking.isNotEmpty) {
                        recipeGroupUserRankingList.addAll(
                          _poppedGroupUserRanking,
                        );
                        _poppedGroupUserRanking.clear();
                      }
                      if (_viewGroupRankings) {
                        recipeGroupUserRankingList.sort((a, b) {
                          final rankingA = a.groupRank;
                          final rankingB = b.groupRank;
                          return rankingA.compareTo(rankingB);
                        });
                      } else {
                        recipeGroupUserRankingList.sort((a, b) {
                          final rankingA = a.userRank;
                          final rankingB = b.userRank;
                          return rankingA.compareTo(rankingB);
                        });
                      }
                    }

                    return Expanded(
                      child: Column(
                        children: [
                          if (_currentTitleIndex == 0)
                            Expanded(
                              child: ListView.builder(
                                itemCount: recipeGroupUserRankingList.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final userRankedPlace =
                                      recipeGroupUserRankingList[index]
                                                  .userRank !=
                                              double.infinity
                                          ? recipeGroupUserRankingList[index]
                                              .userRank
                                              .toInt()
                                              .toString()
                                          : "N/A";

                                  final groupRankedPlace =
                                      recipeGroupUserRankingList[index]
                                                  .groupRank !=
                                              double.infinity
                                          ? recipeGroupUserRankingList[index]
                                              .groupRank
                                              .toInt()
                                              .toString()
                                          : "N/A";

                                  final recipe =
                                      recipeGroupUserRankingList[index].recipe;

                                  return RecipeListTileWidget(
                                    recipe: recipe,
                                    userRanking: userRankedPlace,
                                    groupRanking: groupRankedPlace,
                                    removeValueFromList: removeValueFromList,
                                  );
                                },
                              ),
                            )
                          else if (_currentTitleIndex == 2)
                            Expanded(
                              child: ReorderableListView.builder(
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final movedRecipe = recipeGroupUserRankingList
                                      .removeAt(oldIndex);
                                  recipeGroupUserRankingList.insert(
                                    newIndex,
                                    movedRecipe,
                                  );
                                  setState(() {});
                                },
                                shrinkWrap: true,
                                itemCount: recipeGroupUserRankingList.length,
                                itemBuilder: (context, index) {
                                  final recipe =
                                      recipeGroupUserRankingList[index].recipe;
                                  return ReorderableDragStartListener(
                                    key: ValueKey(recipe.id),
                                    index: index,

                                    child: RecipeReorderableListTileWidget(
                                      recipe: recipe,
                                      ranking: index.toString(),
                                      removeValueFromList: removeValueFromList,
                                    ),
                                  );
                                },
                              ),
                            )
                          else if (_currentTitleIndex == 1)
                            Expanded(
                              child: ListView.builder(
                                itemCount: recipeGroupUserRankingList.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final userRankedPlace =
                                      recipeGroupUserRankingList[index]
                                                  .userRank !=
                                              double.infinity
                                          ? recipeGroupUserRankingList[index]
                                              .userRank
                                              .toInt()
                                              .toString()
                                          : "N/A";

                                  final groupRankedPlace =
                                      recipeGroupUserRankingList[index]
                                                  .groupRank !=
                                              double.infinity
                                          ? recipeGroupUserRankingList[index]
                                              .groupRank
                                              .toInt()
                                              .toString()
                                          : "N/A";

                                  final recipe =
                                      recipeGroupUserRankingList[index].recipe;

                                  return RecipeListTileWidget(
                                    recipe: recipe,
                                    groupRanking: groupRankedPlace,
                                    userRanking: userRankedPlace,
                                    isGroupRatingTile: true,
                                    removeValueFromList: removeValueFromList,
                                  );
                                },
                              ),
                            ),
                          if (_reordering) ...[
                            SizedBox(height: 8),
                            ElevatedButton(
                              // TODO
                              // Make updating not need to pop the screen so the data can refresh properly
                              onPressed: () async {
                                setState(() {
                                  _isSubmitting = true;
                                });
                                final success = await _submitNewRankings(
                                  recipeGroupUserRankingList,
                                );
                                setState(() {
                                  _isSubmitting = false;
                                });
                                if (success && context.mounted) {
                                  context.pop(true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  102,
                                  199,
                                  105,
                                ),
                                maximumSize: Size(300.w, 50.h),
                                minimumSize: Size(300.w, 50.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.black),
                                ),
                              ),
                              child:
                                  _isSubmitting
                                      ? CircularProgressIndicator()
                                      : Text(
                                        "Submit",
                                        style: TextStyle(color: Colors.white),
                                      ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _sortRecipesByRatings(List<RecipeRating> ratings) {
    final averages = <String, double>{};
    final counts = <String, int>{};

    for (var r in ratings) {
      final val = r.ranking?.toDouble() ?? 0.0;
      averages.update(r.recipeId, (curr) => curr + val, ifAbsent: () => val);
      counts.update(r.recipeId, (curr) => curr + 1, ifAbsent: () => 1);
    }

    final sortedIds =
        averages.keys.toList()..sort((a, b) {
          final avgA = averages[a]! / counts[a]!;
          final avgB = averages[b]! / counts[b]!;
          return avgA.compareTo(avgB);
        });

    return sortedIds;
  }

  // TODO
  // Make recipes with the same ranking show as the same ranking instead of whichever gets looked at first
  List<RecipeGroupUserRanking> _buildRecipeGroupUserRanking(
    List<Recipe> recipes,
    List<RecipeRating> ratings,
    List<RecipeRating> userSpecificRatings,
  ) {
    final groupSortedIds = _sortRecipesByRatings(ratings);
    final userSortedIds = _sortRecipesByRatings(userSpecificRatings);

    final List<RecipeGroupUserRanking> recipeGroupUserRanking =
        recipes.map((r) {
          return RecipeGroupUserRanking(
            userRank:
                userSortedIds.contains(r.id)
                    ? userSortedIds.indexOf(r.id).toDouble()
                    : double.infinity,
            groupRank:
                groupSortedIds.contains(r.id)
                    ? groupSortedIds.indexOf(r.id).toDouble()
                    : double.infinity,
            recipe: r,
          );
        }).toList();

    return recipeGroupUserRanking;
  }

  Future<List<RecipeGroupUserRanking>> _fetchRecipeGroupUserRankings() async {
    final recipes = await SupabaseHelper.recipe.getRecipesByGroupId(
      _group?.id ?? '',
    );

    if (recipes == null) return [];

    late final List<RecipeGroupUserRanking> recipeGroupUserRankingList;

    if (_ratings != null) {
      final userSpecificRatings =
          _ratings!
              .where(
                (r) =>
                    r.userId == Supabase.instance.client.auth.currentUser?.id,
              )
              .toList();

      final ratings = _ratings!.toList();

      recipeGroupUserRankingList = _buildRecipeGroupUserRanking(
        recipes,
        ratings,
        userSpecificRatings,
      );
    } else {
      final ratings =
          await SupabaseHelper.recipe.getRatingsByGroupId(_group?.id ?? '') ??
          [];

      final userSpecificRatings =
          ratings
              .where(
                (r) =>
                    r.userId == Supabase.instance.client.auth.currentUser?.id,
              )
              .toList();

      recipeGroupUserRankingList = _buildRecipeGroupUserRanking(
        recipes,
        ratings,
        userSpecificRatings,
      );
    }

    return recipeGroupUserRankingList;
  }

  Future<bool> _submitNewRankings(
    List<RecipeGroupUserRanking> newRankings,
  ) async {
    late final List<RecipeRating> currentUserRankings;

    if (_ratings != null) {
      currentUserRankings =
          _ratings!
              .where(
                (r) =>
                    r.userId == Supabase.instance.client.auth.currentUser?.id,
              )
              .toList();
    } else {
      final ratings =
          await SupabaseHelper.recipe.getRatingsByGroupId(_group?.id ?? '') ??
          [];

      currentUserRankings =
          ratings
              .where(
                (r) =>
                    r.userId == Supabase.instance.client.auth.currentUser?.id,
              )
              .toList();
    }

    final List<RecipeRating> updatedRankings =
        newRankings.map((r) {
          final associatedRankingIndex = currentUserRankings.indexWhere(
            (ranking) => ranking.recipeId == r.recipe.id,
          );

          if (associatedRankingIndex == -1) {
            return RecipeRating(
              id: null,
              createdAt: DateTime.now().toIso8601String(),
              recipeId: r.recipe.id,
              userId: Supabase.instance.client.auth.currentUser?.id ?? '',
              groupId: _group?.id ?? '',
              ranking: newRankings.indexOf(r),
            );
          }

          return RecipeRating(
            id: currentUserRankings[associatedRankingIndex].id,
            createdAt: currentUserRankings[associatedRankingIndex].createdAt,
            recipeId: r.recipe.id,
            userId: Supabase.instance.client.auth.currentUser?.id ?? '',
            groupId: _group?.id ?? '',
            ranking: newRankings.indexOf(r),
          );
        }).toList();

    final response = await SupabaseHelper.recipe.updateRecipeRanking(
      updatedRankings,
    );

    if (response != true) {
      showSnackbar(context, 'Failed to update rankings. Please try again.');
      return false;
    } else {
      showSuccessSnackbar(context, 'Rankings updated successfully');
    }

    return true;
  }
}
