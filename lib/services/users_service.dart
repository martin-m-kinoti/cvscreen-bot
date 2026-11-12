import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/app_user.dart';

/// Recruiter directory access. The app's anon key cannot read or delete rows in
/// Supabase's `auth.users` table, so this delegates to SECURITY DEFINER
/// functions that run server-side and are gated to recruiters
/// (see supabase/admin_user_directory.sql).
class UsersService {
  Future<List<AppUser>> fetchUsers() async {
    final rows = await supabase.rpc('admin_list_users');
    final list = (rows as List?) ?? const [];
    return list
        .map((row) => AppUser.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> deleteUser(String id) =>
      supabase.rpc('admin_delete_user', params: {'target': id});

  Future<void> updateUserEmail(String id, String email) => supabase.rpc(
        'admin_update_user_email',
        params: {'target': id, 'new_email': email.trim()},
      );

  static String describeError(Object error) {
    if (error is PostgrestException) {
      final message = error.message;
      if (message.contains('Not authorized')) return 'Only recruiters can manage users.';
      if (message.contains('already in use')) return 'That email is already in use.';
      if (message.contains('valid email')) return 'Enter a valid email address.';
      return message;
    }
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Could not reach the database. Check your connection and try again.';
    }
    if (message.contains('Not authorized')) {
      return 'Only recruiters can manage users.';
    }
    return message;
  }
}
