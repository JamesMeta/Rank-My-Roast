import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/extra/create_event_extra.dart';
import 'package:rankmyroast/classes/extra/select_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/recipe.dart';
import 'package:rankmyroast/classes/modals/schedule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewEventDialogWidget extends StatelessWidget {
  final Schedule event;

  const ViewEventDialogWidget({super.key, required this.event});

  String _formatServedAt(String servedAt) {
    try {
      final date = DateTime.parse(servedAt).toLocal();
      final hour = date.hour == 0 || date.hour == 12 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $period';
    } catch (_) {
      return servedAt;
    }
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green;
    final imageUrl = event.recipe.publicImageUrl;
    final servedAtText = _formatServedAt(event.servedAt);
    final bool isOwner =
        event.userId == Supabase.instance.client.auth.currentUser?.id;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: primaryGreen.withOpacity(0.35), width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.recipe.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'From ${event.group.name}',
            style: TextStyle(fontSize: 14, color: Colors.green[600]),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 64,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 200,
                child:
                    imageUrl != null
                        ? CachedNetworkImage(
                          httpHeaders: {
                            'Authorization':
                                'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
                          },
                          imageUrl: imageUrl,
                          fit: BoxFit.fill,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 56),
                              ),
                        )
                        : Image.asset(
                          'assets/images/rankmyroast_icon4.png',
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoTile(
              Icons.calendar_month,
              'Scheduled for',
              servedAtText,
              Colors.green[700]!,
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              Icons.restaurant_menu,
              'Recipe',
              event.recipe.name,
              Colors.green[700]!,
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              Icons.group,
              'Group',
              event.group.name,
              Colors.green[700]!,
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              Icons.note,
              'Notes',
              event.notes != null && event.notes!.isNotEmpty
                  ? event.notes!
                  : 'No notes provided.',
              Colors.green[700]!,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        if (isOwner)
          TextButton(
            onPressed: () async {
              final response = await context.push(
                "/base/create-event",
                extra: CreateEventExtra(event: event),
              );

              if (response != null && response is bool && response) {
                context.pop(true);
              } else {
                context.pop();
              }
            },

            style: TextButton.styleFrom(foregroundColor: Colors.green[800]),
            child: const Text('Edit'),
          ),

        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.green[800]),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
