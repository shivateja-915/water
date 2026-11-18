import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/drink_type.dart';
import '../data/repositories/drink_type_repository.dart';
import 'auth_provider.dart';

final drinkTypeRepositoryProvider =
    Provider<DrinkTypeRepository>((ref) => DrinkTypeRepository());

/// Reactive userId that updates on auth state changes
final _dtUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).userId;
});

final drinkTypesProvider =
    StateNotifierProvider<DrinkTypesNotifier, AsyncValue<List<DrinkType>>>(
        (ref) {
  final repo = ref.read(drinkTypeRepositoryProvider);
  final userId = ref.watch(_dtUserIdProvider);
  return DrinkTypesNotifier(repo, userId);
});

class DrinkTypesNotifier
    extends StateNotifier<AsyncValue<List<DrinkType>>> {
  final DrinkTypeRepository _repo;
  final String? _userId;

  DrinkTypesNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    loadDrinkTypes();
  }

  Future<void> loadDrinkTypes() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final types = await _repo.getDrinkTypes(_userId);
      state = AsyncValue.data(types);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDrinkType(DrinkType type) async {
    await _repo.addDrinkType(type);
    await loadDrinkTypes();
  }

  Future<void> updateDrinkType(DrinkType type) async {
    await _repo.updateDrinkType(type);
    await loadDrinkTypes();
  }

  Future<void> archiveDrinkType(String id) async {
    await _repo.archiveDrinkType(id);
    await loadDrinkTypes();
  }
}

/// Currently selected drink type
final selectedDrinkTypeProvider = StateProvider<DrinkType?>((ref) {
  final types = ref.watch(drinkTypesProvider).valueOrNull;
  if (types != null && types.isNotEmpty) {
    return types.first;
  }
  return null;
});
