import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://rcmxkyplzqzsxnuyzmax.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjbXhreXBsenF6c3hudXl6bWF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxMTYzNTQsImV4cCI6MjA5OTY5MjM1NH0.L1xNo6a577vL-RVfjMhGd4gMviv2aPDJpRlTUVe_BCQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;
}
