import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/mixin/snackbar_service.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

class RatingDialogWidget extends StatefulWidget {
  final Recipe recipe;
  final Group? group;
  final int? pastRating;

  const RatingDialogWidget({
    super.key,
    required this.recipe,
    this.group,
    this.pastRating,
  });

  @override
  State<RatingDialogWidget> createState() => _RatingDialogWidgetState();
}

class _RatingDialogWidgetState extends State<RatingDialogWidget>
    with SnackbarService {
  final TextEditingController _ratingController = TextEditingController();
  late final Recipe _recipe;
  late final Group? _group;

  bool isLoading = false;

  @override
  void initState() {
    _recipe = widget.recipe;
    _group = widget.group;

    if (widget.pastRating != null) {
      _ratingController.text = widget.pastRating.toString();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Text(
          "Leave Rating",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Leave a rating between 1 and 10, you can change this rating at any time.",
              style: TextStyle(fontSize: 14.sp),
            ),
            Row(
              children: [
                Expanded(child: SizedBox()),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[600]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _ratingController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    " / 10",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {
            context.pop();
          },
          child: Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () async {
            if (isLoading) return;

            setState(() {
              isLoading = true;
            });

            final input = _ratingController.text.trim();
            final ratingValue = int.tryParse(input);

            if (ratingValue == null || ratingValue < 1 || ratingValue > 10) {
              showSnackbar(
                context,
                "Please enter a valid rating between 1 and 10.",
              );

              setState(() {
                isLoading = false;
              });
              return;
            }

            final response = await SupabaseHelper.recipe.upsertRecipeRating(
              _recipe,
              _group,
              ratingValue,
            );

            setState(() {
              isLoading = false;
            });

            if (!context.mounted) return;

            if (response == true) {
              showSuccessSnackbar(context, "Rating submitted successfully!");
              context.pop();
            } else {
              showSnackbar(
                context,
                "Failed to submit rating. Please try again.",
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: !isLoading ? Text("Submit") : CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ratingController.dispose();
    super.dispose();
  }
}
