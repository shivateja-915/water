import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink_type.dart';
import '../services/supabase_service.dart';

class DrinkTypeRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Get all drink types (global defaults + user custom)
  Future<List<DrinkType>> getDrinkTypes(String userId) async {
    final response = await _client
        .from('drink_types')
        .select()
        .or('user_id.is.null,user_id.eq.$userId')
        .eq('is_active', true)
        .order('is_default', ascending: false)
        .order('name');

    return (response as List)
        .map((e) => DrinkType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DrinkType?> getDrinkType(String id) async {
    final response = await _client
        .from('drink_types')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DrinkType.fromJson(response);
  }

  Future<DrinkType> addDrinkType(DrinkType type) async {
    await _client.from('drink_types').insert(type.toJson());
    return type;
  }

  Future<DrinkType> updateDrinkType(DrinkType type) async {
    await _client
        .from('drink_types')
        .update(type.toJson())
        .eq('id', type.id);
    return type;
  }

  /// Soft-delete (archive) - preserves history
  Future<void> archiveDrinkType(String id) async {
    await _client
        .from('drink_types')
        .update({'is_active': false}).eq('id', id);
  }
}
