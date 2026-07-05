import 'package:rankmyroast/services/modules/supabase_helper_auth.dart';
import 'package:rankmyroast/services/modules/supabase_helper_groups.dart';
import 'package:rankmyroast/services/modules/supabase_helper_recipe.dart';
import 'package:rankmyroast/services/modules/supabase_helper_schedule.dart';
import 'package:rankmyroast/services/modules/supabase_helper_storage.dart';
import 'package:rankmyroast/services/modules/supabase_helper_users.dart';

class SupabaseHelper {
  static final groups = SupabaseHelperGroups();
  static final auth = SupabaseHelperAuth();
  static final users = SupabaseHelperUsers();
  static final storage = SupabaseHelperStorage();
  static final recipe = SupabaseHelperRecipe();
  static final schedule = SupabaseHelperSchedule();
}
