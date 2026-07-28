import 'package:flutter/material.dart';
import 'package:rankmyroast/classes/extra/select_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/calendar/screens/create/screens/widgets/select_recipe_tile_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/widgets/recipe_tile_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectRecipeScreen extends StatefulWidget {
  final SelectRecipeExtra? extra;

  const SelectRecipeScreen({super.key, required this.extra});

  @override
  State<SelectRecipeScreen> createState() => _SelectRecipeScreenState();
}

class _SelectRecipeScreenState extends State<SelectRecipeScreen> {
  late final List<Recipe> _recipes;

  @override
  void initState() {
    if (widget.extra != null) {
      _recipes = widget.extra!.recipes;
    } else {
      _recipes = [];
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Recipe",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,

        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double idealItemWidth = 140.0;

            int crossAxisCount =
                (constraints.maxWidth / idealItemWidth).floor();

            if (crossAxisCount < 2) crossAxisCount = 2;

            return _recipes.isNotEmpty
                ? GridView.builder(
                  shrinkWrap: true,

                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        Navigator.pop(context, recipe);
                      },
                      child: SelectRecipeTileWidget(recipe: recipe),
                    );
                  },
                )
                : const Center(child: Text('No recipes available.'));
          },
        ),
      ),
    );
  }
}
