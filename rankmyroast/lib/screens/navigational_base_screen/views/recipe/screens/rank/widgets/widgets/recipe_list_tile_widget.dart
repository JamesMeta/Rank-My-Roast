import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeListTileWidget extends StatelessWidget {
  final Recipe recipe;
  final String userRanking;
  final String groupRanking;
  final bool isEdit;
  final bool isGroupRatingTile;

  const RecipeListTileWidget({
    super.key,
    required this.recipe,
    required this.userRanking,
    required this.groupRanking,
    this.isEdit = false,
    this.isGroupRatingTile = false,
  });

  @override
  Widget build(BuildContext context) {
    final recipeImageUrl = recipe.publicImageUrl;

    final userRankingInt = int.tryParse(userRanking) ?? 0;
    final groupRankingInt = int.tryParse(groupRanking) ?? 0;

    final difference = userRankingInt - groupRankingInt;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!),
          color:
              isEdit
                  ? const Color.fromARGB(255, 102, 199, 105)
                  : isGroupRatingTile
                  ? const Color.fromARGB(255, 37, 87, 39)
                  : Colors.green,
          boxShadow: [BoxShadow(color: Colors.grey)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Custom Leading Image
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      recipeImageUrl != null
                          ? CachedNetworkImage(
                            httpHeaders: {
                              'Authorization':
                                  'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
                            },
                            imageUrl: recipeImageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.error),
                          )
                          : Image.asset(
                            "assets/images/rankmyroast_icon4.png",
                            fit: BoxFit.cover,
                          ),
                ),
              ),
              const SizedBox(width: 16), // Spacing between image and text
              // Title area expands to take up remaining space
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: isGroupRatingTile ? 8 : 10,
                      child: Text(
                        recipe.name,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14.sp,
                          overflow: TextOverflow.ellipsis,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Trailing ranking
                    Flexible(
                      flex: isGroupRatingTile ? 5 : 4,
                      fit: FlexFit.loose,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              "Ranking",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                overflow: TextOverflow.ellipsis,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: isGroupRatingTile ? 4 : 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    isGroupRatingTile
                                        ? Colors.grey[800]
                                        : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isGroupRatingTile
                                        ? groupRanking
                                        : userRanking,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      overflow: TextOverflow.ellipsis,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isGroupRatingTile
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),

                                  if (isGroupRatingTile) ...[
                                    if (difference == 0)
                                      Icon(
                                        CupertinoIcons.equal,
                                        color: Colors.white,
                                      )
                                    else if (difference >= 0)
                                      Icon(
                                        Icons.arrow_upward,
                                        color: Colors.green,
                                      )
                                    else
                                      Icon(
                                        Icons.arrow_downward,
                                        color: Colors.red,
                                      ),
                                    Text(
                                      difference.abs().toString(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        overflow: TextOverflow.ellipsis,
                                        color:
                                            difference == 0
                                                ? Colors.white
                                                : difference > 0
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
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
          ),
        ),
      ),
    );
  }
}
