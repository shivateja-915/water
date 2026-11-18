import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/developer_preferences_repository.dart';

final developerPreferencesRepoProvider = Provider<DeveloperPreferencesRepository>((ref) {
  return DeveloperPreferencesRepository();
});

class DeveloperModeState {
  final bool isUnlocked;
  final int tapCount;

  const DeveloperModeState({
    this.isUnlocked = false,
    this.tapCount = 0,
  });

  DeveloperModeState copyWith({
    bool? isUnlocked,
    int? tapCount,
  }) {
    return DeveloperModeState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      tapCount: tapCount ?? this.tapCount,
    );
  }
}

class DeveloperModeNotifier extends StateNotifier<DeveloperModeState> {
  final DeveloperPreferencesRepository _repo;
  Timer? _longPressTimer;

  DeveloperModeNotifier(this._repo) : super(const DeveloperModeState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final unlocked = await _repo.getIsUnlocked();
    state = state.copyWith(isUnlocked: unlocked);
  }

  /// Registers a tap on App Version.
  Future<String?> registerTap() async {
    if (state.isUnlocked) {
      return 'Developer Mode is already active.';
    }

    final newCount = state.tapCount + 1;

    if (newCount >= 3) {
      state = state.copyWith(isUnlocked: true, tapCount: 0);
      await _repo.setIsUnlocked(true);
      return '🎉 Developer Mode Enabled!';
    } else {
      state = state.copyWith(tapCount: newCount);
      final remaining = 3 - newCount;
      return 'You are $remaining step${remaining > 1 ? 's' : ''} away from Developer Mode.';
    }
  }

  /// Long press logo trigger (5 Seconds)
  void startLongPress(VoidCallback onUnlocked) {
    if (state.isUnlocked) return;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(seconds: 5), () async {
      state = state.copyWith(isUnlocked: true, tapCount: 0);
      await _repo.setIsUnlocked(true);
      onUnlocked();
    });
  }

  void cancelLongPress() {
    _longPressTimer?.cancel();
  }

  /// Lock Developer Mode
  Future<void> lockDeveloperMode() async {
    state = const DeveloperModeState(isUnlocked: false, tapCount: 0);
    await _repo.setIsUnlocked(false);
  }
}

final developerModeProvider =
    StateNotifierProvider<DeveloperModeNotifier, DeveloperModeState>((ref) {
  final repo = ref.watch(developerPreferencesRepoProvider);
  return DeveloperModeNotifier(repo);
});
