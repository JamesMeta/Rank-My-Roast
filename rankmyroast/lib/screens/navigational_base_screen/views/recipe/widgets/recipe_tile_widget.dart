import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeTileWidget extends StatefulWidget {
  final Recipe recipe;

  const RecipeTileWidget({super.key, required this.recipe});

  @override
  State<RecipeTileWidget> createState() => _RecipeTileWidgetState();
}

class _RecipeTileWidgetState extends State<RecipeTileWidget> {
  late Recipe _recipe;
  late String? _recipeImageUrl;

  @override
  void initState() {
    _recipe = widget.recipe;
    _recipeImageUrl = _recipe.publicImageUrl;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RecipeTileWidget oldWidget) {
    if (oldWidget.recipe.id != widget.recipe.id) {
      _recipe = widget.recipe;
      _recipeImageUrl = _recipe.publicImageUrl;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GridTile(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[700]!,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[500]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child:
                    _recipeImageUrl != null
                        ? CachedNetworkImage(
                          httpHeaders: {
                            'Authorization':
                                'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
                          },
                          imageUrl: _recipeImageUrl!,

                          fit: BoxFit.fill,

                          placeholder:
                              (context, url) =>
                                  const CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        )
                        : Image.asset(
                          "assets/images/rankmyroast_icon4.png",
                          fit: BoxFit.fill,
                        ),
              ),
            ),

            Divider(height: 1, color: Colors.grey[300]),

            SizedBox(height: 8.h),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _recipe.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
