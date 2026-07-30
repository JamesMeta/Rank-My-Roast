import 'package:flutter/material.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/rank/widgets/widgets/recipe_list_tile_widget.dart';

class RecipeReorderableListTileWidget extends StatelessWidget {
  final Recipe recipe;
  final String ranking;

  const RecipeReorderableListTileWidget({
    super.key,
    required this.recipe,
    required this.ranking,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 1, child: Icon(Icons.drag_handle)),
        Expanded(
          flex: 9,
          child: RecipeListTileWidget(
            recipe: recipe,
            userRanking: ranking,
            groupRanking: ranking,
            isEdit: true,
          ),
        ),
      ],
    );
  }
}
