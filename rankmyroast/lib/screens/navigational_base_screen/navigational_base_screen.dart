import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/calendar/schedule_view.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/groups/groups_view.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/home/home_view.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/recipe_view.dart';
import 'package:rankmyroast/screens/navigational_base_screen/widgets/create_username_dialog_widget.dart';
import 'package:rankmyroast/screens/navigational_base_screen/widgets/sign_out_dialog_widget.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

// ignore: constant_identifier_names
const SELECTED_ICON_SIZE = 36.0;
// ignore: constant_identifier_names
const UNSELECTED_ICON_SIZE = 32.0;

class NavigationalBaseScreen extends StatefulWidget {
  const NavigationalBaseScreen({super.key});

  @override
  State<NavigationalBaseScreen> createState() => _NavigationalBaseScreenState();
}

class _NavigationalBaseScreenState extends State<NavigationalBaseScreen> {
  int navigationalIndex = 1;

  final List<Widget> navigationalViews = [
    ScheduleView(),
    HomeView(),
    GroupsView(),
    RecipeView(),
  ];

  @override
  void initState() {
    _handleUsername();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: _goToSettings,
            icon: Icon(Icons.settings, color: Colors.white),
          ),
          IconButton(
            onPressed:
                () => showDialog(
                  context: context,
                  builder: (BuildContext context) => SignOutDialogWidget(),
                ),
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Container(child: navigationalViews[navigationalIndex]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color.fromARGB(255, 49, 119, 51),
          height: 60.h,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          iconTheme: WidgetStatePropertyAll(
            const IconThemeData(color: Colors.white),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.green, // The main bar color
          selectedIndex: navigationalIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          onDestinationSelected:
              (index) => setState(() => navigationalIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.calendar_month_outlined,
                size: UNSELECTED_ICON_SIZE,
              ),
              selectedIcon: Icon(
                Icons.calendar_month,
                size: SELECTED_ICON_SIZE,
              ),
              label: 'Calendar',
            ),

            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: UNSELECTED_ICON_SIZE),
              selectedIcon: Icon(Icons.home, size: SELECTED_ICON_SIZE),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined, size: UNSELECTED_ICON_SIZE),
              selectedIcon: Icon(Icons.group, size: SELECTED_ICON_SIZE),
              label: 'Group',
            ),
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined, size: UNSELECTED_ICON_SIZE),
              selectedIcon: Icon(Icons.kitchen, size: SELECTED_ICON_SIZE),
              label: 'Recipe',
            ),
          ],
        ),
      ),
    );
  }

  void _goToSettings() {
    context.push("/settings");
  }

  Future<void> _handleUsername() async {
    final hasUsername = await SupabaseHelper.users.checkForUsername();

    if (hasUsername) {
      return;
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => CreateUsernameDialogWidget(),
      );
    }
  }
}
