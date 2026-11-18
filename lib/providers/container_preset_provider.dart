import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/container_preset.dart';
import '../data/repositories/container_preset_repository.dart';
import 'auth_provider.dart';

final containerPresetRepositoryProvider =
    Provider<ContainerPresetRepository>((ref) => ContainerPresetRepository());

/// Reactive userId that updates on auth state changes
final _cpUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).userId;
});

final containerPresetsProvider = StateNotifierProvider<
    ContainerPresetsNotifier, AsyncValue<List<ContainerPreset>>>((ref) {
  final repo = ref.read(containerPresetRepositoryProvider);
  final userId = ref.watch(_cpUserIdProvider);
  return ContainerPresetsNotifier(repo, userId);
});

class ContainerPresetsNotifier
    extends StateNotifier<AsyncValue<List<ContainerPreset>>> {
  final ContainerPresetRepository _repo;
  final String? _userId;

  ContainerPresetsNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    loadPresets();
  }

  Future<void> loadPresets() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final presets = await _repo.getPresets(_userId);
      state = AsyncValue.data(presets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPreset(ContainerPreset preset) async {
    await _repo.addPreset(preset);
    await loadPresets();
  }

  Future<void> updatePreset(ContainerPreset preset) async {
    await _repo.updatePreset(preset);
    await loadPresets();
  }

  Future<void> deletePreset(String id) async {
    final current = state.valueOrNull ?? [];
    if (current.length <= 1) return; // Block deletion of last preset
    await _repo.deletePreset(id);
    await loadPresets();
  }

  Future<void> createDefaults() async {
    if (_userId == null) return;
    await _repo.createDefaults(_userId);
    await loadPresets();
  }
}
