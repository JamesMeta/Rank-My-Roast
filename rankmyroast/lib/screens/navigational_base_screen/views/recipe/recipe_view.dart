import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/extra/create_recipe_extra.dart';
import 'package:rankmyroast/classes/extra/view_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/group_order.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/widgets/recipe_tile_widget.dart';
import 'package:rankmyroast/services/sqlite_helper.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({super.key});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  bool groupRecipes = true;
  Group? _selectedGroup;

  List<Recipe> _recipes = [];

  late Future<List<Group>?> _groupsList;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          FutureBuilder(
            future: _groupsList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recipes",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "No recipes",
                          style: TextStyle(
                            fontSize: 14.sp,

                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                    IconButton(
                      onPressed: () {},
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.w,
                      ),
                      icon: Icon(Icons.add, color: Colors.white, size: 22.sp),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          side: BorderSide(color: Colors.transparent, width: 1),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox();
              } else {
                final groups = snapshot.data ?? [];

                return Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recipes",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_selectedGroup != null ? _selectedGroup!.recipes.length : 0} recipes",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                    IconButton(
                      onPressed: () async {
                        _navigateToCreateRecipeScreen(groups, null);
                      },
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.w,
                      ),
                      icon: Icon(Icons.add, color: Colors.white, size: 22.sp),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          side: BorderSide(color: Colors.transparent, width: 1),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          SizedBox(height: 8.h),

          TextField(
            controller: _searchController,
            onChanged: (value) => _runFilter(value),
            decoration: InputDecoration(
              hintText: "Search recipes...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          SizedBox(height: 8.h),

          FutureBuilder(
            future: _groupsList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.connectionState == ConnectionState.done) {
                final groups = snapshot.data;

                if (groups != null && groups.isNotEmpty) {
                  // late final List<Group> newGroups;
                  // final sqliteHelper = SqliteHelper();

                  // if (sqliteHelper.pastGroupsContainsCurrentGroups(
                  //   groups,
                  //   _groupOrders,
                  // )) {
                  //   newGroups =
                  //       _groupOrders
                  //           .map(
                  //             (order) => groups.firstWhere(
                  //               (group) => group.id == order.groupId,
                  //             ),
                  //           )
                  //           .toList();
                  // } else {
                  //   newGroups =
                  //       _groupOrders
                  //           .map(
                  //             (order) => groups.firstWhere(
                  //               (group) => group.id == order.groupId,
                  //             ),
                  //           )
                  //           .toList();
                  //   newGroups.addAll(
                  //     groups.where((group) => !newGroups.contains(group)),
                  //   );
                  // }

                  // _selectedGroup = newGroups.first;
                  // _recipes = _selectedGroup!.recipes;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          groups.map((group) {
                            final isSelected =
                                _selectedGroup != null &&
                                _selectedGroup!.id == group.id;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(group.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedGroup = selected ? group : null;
                                    _recipes = selected ? group.recipes : [];
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  );
                } else if (groups != null && groups.isEmpty) {
                  return Center(child: Text("No groups found"));
                } else {
                  return Center(child: Text("The Data is null"));
                }
              } else {
                return Center(child: Text("The Data is never coming"));
              }
            },
          ),

          SizedBox(height: 8.h),

          Expanded(
            child: FutureBuilder(
              future: _groupsList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.connectionState == ConnectionState.done) {
                  final groups = snapshot.data;

                  if (groups != null && _recipes.isNotEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const double idealItemWidth = 140.0;

                        int crossAxisCount =
                            (constraints.maxWidth / idealItemWidth).floor();

                        if (crossAxisCount < 2) crossAxisCount = 2;

                        return RefreshIndicator(
                          onRefresh: () async {
                            await _refreshData();
                          },
                          color: Colors.white, // Color of the spinner
                          backgroundColor: Colors.green,
                          child: GridView.builder(
                            shrinkWrap: true,

                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.95,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemCount: _recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = _recipes[index];
                              return GestureDetector(
                                onTap: () async {
                                  final response = await context.push(
                                    "/base/view-recipe",
                                    extra: ViewRecipeExtra(
                                      group: _selectedGroup!,
                                      recipe: recipe,
                                      userGroups: groups,
                                    ),
                                  );

                                  if (response != null &&
                                      response is bool &&
                                      response) {
                                    _refreshData();
                                  }
                                },
                                child: RecipeTileWidget(recipe: recipe),
                              );
                            },
                          ),
                        );
                      },
                    );
                  } else if (groups != null && _recipes.isEmpty) {
                    return Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              // Industry standard: await the refresh logic directly
                              // so the indicator stays visible until the data is fetched.
                              await _refreshData();
                            },
                            child: ListView(
                              // This is the critical line:
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  // Ensure the empty state takes up the full height
                                  // so the entire screen is "pullable"
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: const Center(
                                    child: Text("No recipes found"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Center(child: Text("The Data is null"));
                  }
                } else {
                  return Center(child: Text("The Data is never coming"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _runFilter(String enteredKeyword) {
    List<Recipe> results = [];
    if (enteredKeyword.isEmpty) {
      results = _selectedGroup?.recipes ?? [];
    } else {
      results =
          _selectedGroup?.recipes
              .where(
                (recipe) => recipe.name.toLowerCase().contains(
                  enteredKeyword.toLowerCase(),
                ),
              )
              .toList() ??
          [];
    }

    setState(() {
      _recipes = results;
    });
  }

  Future<void> _navigateToCreateRecipeScreen(
    List<Group> groups,
    Recipe? recipe,
  ) async {
    await context.push(
      "/base/create-recipe",
      extra: CreateRecipeExtra(
        groups: groups,
        selectedGroup: _selectedGroup,
        recipeToEdit: recipe,
      ),
    );
  }

  Future<void> _loadData() async {
    final sqliteHelper = SqliteHelper();
    _groupsList = SupabaseHelper.groups.getGroupsForUser().then((groups) async {
      try {
        List<Group> newGroups;
        final groupOrders = await sqliteHelper.getGroupOrders();
        if (sqliteHelper.pastGroupsContainsCurrentGroups(
          groups!,
          groupOrders,
        )) {
          newGroups =
              groupOrders
                  .map(
                    (order) =>
                        groups.firstWhere((group) => group.id == order.groupId),
                  )
                  .toList();
        } else {
          newGroups =
              groupOrders
                  .map(
                    (order) =>
                        groups.firstWhere((group) => group.id == order.groupId),
                  )
                  .toList();
          newGroups.addAll(groups.where((group) => !newGroups.contains(group)));
        }
        return newGroups;
      } on Exception {
        return groups;
      }
    });

    try {
      _selectedGroup = (await _groupsList)?.first;
      _recipes = _selectedGroup?.recipes ?? [];
    } on Exception {
      _selectedGroup = null;
    }
  }

  Future<void> _refreshData() async {
    _groupsList = SupabaseHelper.groups.getGroupsForUser();
    try {
      _groupsList.then((groups) {
        if (groups != null) {
          final currentGroup = groups.where(
            (element) => element.id == _selectedGroup?.id,
          );
          if (currentGroup.isNotEmpty) {
            setState(() {
              _selectedGroup = currentGroup.first;
              _recipes = _selectedGroup?.recipes ?? [];
            });
          } else {
            setState(() {
              _selectedGroup = groups.first;
              _recipes = _selectedGroup?.recipes ?? [];
            });
          }
        }
      });
    } on Exception {
      _selectedGroup = null;
    }
  }
}
