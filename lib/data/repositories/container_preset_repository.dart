import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/container_preset.dart';
import '../services/supabase_service.dart';

class ContainerPresetRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<ContainerPreset>> getPresets(String userId) async {
    final response = await _client
        .from('container_presets')
        .select()
        .eq('user_id', userId)
        .order('amount_ml');

    return (response as List)
        .map((e) => ContainerPreset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContainerPreset> addPreset(ContainerPreset preset) async {
    await _client.from('container_presets').insert(preset.toJson());
    return preset;
  }

  Future<ContainerPreset> updatePreset(ContainerPreset preset) async {
    await _client
        .from('container_presets')
        .update(preset.toJson())
        .eq('id', preset.id);
    return preset;
  }

  Future<void> deletePreset(String id) async {
    await _client.from('container_presets').delete().eq('id', id);
  }

  Future<void> createDefaults(String userId) async {
    final defaults = [
      ContainerPreset(
        id: '',
        userId: userId,
        name: 'Glass',
        amountMl: 250,
      ),
      ContainerPreset(
        id: '',
        userId: userId,
        name: 'Bottle',
        amountMl: 500,
      ),
    ];

    for (final preset in defaults) {
      await _client.from('container_presets').insert({
        'user_id': preset.userId,
        'name': preset.name,
        'amount_ml': preset.amountMl,
      });
    }
  }
}
