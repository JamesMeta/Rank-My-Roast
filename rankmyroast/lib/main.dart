import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/extra/create_recipe_extra.dart';
import 'package:rankmyroast/classes/extra/rank_recipe_extra.dart';
import 'package:rankmyroast/classes/extra/view_recipe_extra.dart';
import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/screens/login/confirm_email_screen.dart';
import 'package:rankmyroast/screens/login/create_account_screen.dart';
import 'package:rankmyroast/screens/login/login_screen.dart';
import 'package:rankmyroast/screens/navigational_base_screen/navigational_base_screen.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/groups/screens/create_group_screen.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/create/create_recipe_screen.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/rank/rank_recipe_screen.dart';
import 'package:rankmyroast/screens/navigational_base_screen/views/recipe/screens/viewer/recipe_viewer.dart';
import 'package:rankmyroast/screens/settings/settings_screen.dart';
import 'package:rankmyroast/services/sqlite_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

const supabaseUrl = "https://ozmzpnayygajicxafxfm.supabase.co";
const supabaseKey = "sb_publishable_zTr-mF2b6CCWgssJZEgMjQ_vUwB62oJ";
const supabaseFunctionsVersion = 1.0;
const sqliteTableVersion = 1.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final dbHelper = SqliteHelper();
  final db = await dbHelper.database;

  runApp(const MainApp());
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (_, __) => '/base'),
    GoRoute(
      path: '/base',
      builder: (BuildContext context, GoRouterState state) {
        return const NavigationalBaseScreen();
      },
      routes: [
        GoRoute(
          path: '/create-group',
          builder: (context, state) {
            final extra = state.extra;
            if (extra != null && extra is Group) {
              return CreateGroupScreen(groupToEdit: extra);
            }

            return const CreateGroupScreen(groupToEdit: null);
          },
        ),
        GoRoute(
          path: '/create-recipe',
          builder: (context, state) {
            final extra = state.extra;
            if (extra != null && extra is CreateRecipeExtra) {
              return CreateRecipeScreen(
                recipeToEdit: extra.recipeToEdit,
                selectedGroup: extra.selectedGroup,
                groups: extra.groups,
                isCopying: extra.isCopying,
              );
            }

            return const CreateRecipeScreen(groups: []);
          },
        ),
        GoRoute(
          path: '/view-recipe',
          builder: (context, state) {
            final extra = state.extra;
            if (extra != null && extra is ViewRecipeExtra) {
              final recipe = extra.recipe;
              final group = extra.group;
              final userGroups = extra.userGroups;

              return RecipeViewer(
                recipe: recipe,
                group: group,
                userGroups: userGroups,
              );
            }
            return const RecipeViewer();
          },
        ),
        GoRoute(
          path: '/rank-recipe',
          builder: (context, state) {
            final extra = state.extra;
            if (extra != null && extra is RankRecipeExtra) {
              final ratings = extra.ratings;
              final recipeToRank = extra.recipeToRank;
              final group = extra.group;

              return RankRecipeScreen(
                ratings: ratings,
                group: group,
                recipeToRank: recipeToRank,
              );
            }
            return const RecipeViewer();
          },
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
      routes: [
        GoRoute(
          path: '/create-account',
          builder: (context, state) => CreateAccountScreen(),
          routes: [
            GoRoute(
              path: '/confirm-email',
              builder:
                  (context, state) =>
                      ConfirmEmailScreen(extra: state.extra as List<String>),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
  redirect: (context, state) async {
    //TODO
    // Add a versioning check

    final session = Supabase.instance.client.auth.currentSession;
    final isLoggingIn = state.matchedLocation.startsWith('/login');
    final isCreatingAccount = state.matchedLocation.startsWith(
      '/create-account',
    );
    final isConfirmingEmail = state.matchedLocation.startsWith(
      '/confirm-email',
    );

    if (session?.refreshToken != null) {
      try {
        final response = await Supabase.instance.client.auth.refreshSession(
          session?.refreshToken,
        );
        if (response.session != null && isLoggingIn) {
          return '/base';
        } else {
          return null;
        }
      } on Exception {
        return '/login';
      }
    }

    if (!isLoggingIn && !isCreatingAccount && !isConfirmingEmail) {
      return '/login';
    }

    return null;
  },
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder:
          (context, child) => MaterialApp.router(
            title: 'MenuPlus',
            routerConfig: _router,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
              brightness: Brightness.light,
              fontFamily: "opensans",
              textTheme: TextTheme(
                titleLarge: TextStyle(
                  fontSize: 40.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(
                  fontSize: 28.spMax,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
            darkTheme: ThemeData(),
          ),
    );
  }
}
