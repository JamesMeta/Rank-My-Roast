import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/extra/rank_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';

class GroupTileWidget extends StatelessWidget {
  final Group group;
  final VoidCallback? editGroupCallback;

  const GroupTileWidget({
    super.key,
    required this.group,
    this.editGroupCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          border: Border.all(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            group.name,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "${group.groupMembers.length} members | ${group.recipes.length} recipes",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  context.push(
                    "/base/rank-recipe",
                    extra: RankRecipeExtra(
                      ratings: null,
                      recipeToRank: null,
                      group: group,
                    ),
                  );
                },
                icon: Icon(Icons.rate_review, color: Colors.white),
              ),
              IconButton(
                onPressed: () async {
                  final refresh = await context.push(
                    '/base/create-group',
                    extra: group,
                  );
                  if (refresh == true && editGroupCallback != null) {
                    editGroupCallback!();
                  }
                },
                icon: Icon(Icons.edit, color: Colors.white, size: 20.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
