import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  AppConfig._();

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in .env');
    }
    return value;
  }

  /// Call once from main() before runApp.
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

/// Shortcut used across the app.
SupabaseClient get supabase => Supabase.instance.client;