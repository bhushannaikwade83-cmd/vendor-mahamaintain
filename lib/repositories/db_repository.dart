import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseDbRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<List<dynamic>> getUserProperties(String userId) async {
    try {
      final response = await _client
          .from('properties')
          .select()
          .eq('user_id', userId);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  Future<List<dynamic>> getUserTransactions(String userId) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _client
          .from('users')
          .update(data)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> createProperty(Map<String, dynamic> data) async {
    try {
      await _client.from('properties').insert(data);
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) async {
    try {
      await _client
          .from('properties')
          .update(data)
          .eq('id', propertyId);
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  Future<void> createTransaction(Map<String, dynamic> data) async {
    try {
      await _client.from('transactions').insert(data);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Real-time subscriptions
  Stream<List<dynamic>> watchUserProperties(String userId) {
    return _client
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Stream<List<dynamic>> watchUserTransactions(String userId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}
