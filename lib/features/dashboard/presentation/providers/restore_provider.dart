import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class RestoreCardState {
  final int restoreCount;
  final bool hasRestored;
  final bool dismissedRestoreCard;

  RestoreCardState({
    this.restoreCount = 0,
    this.hasRestored = false,
    this.dismissedRestoreCard = false,
  });

  bool get shouldShowCard => restoreCount > 0 && !hasRestored && !dismissedRestoreCard;

  RestoreCardState copyWith({
    int? restoreCount,
    bool? hasRestored,
    bool? dismissedRestoreCard,
  }) {
    return RestoreCardState(
      restoreCount: restoreCount ?? this.restoreCount,
      hasRestored: hasRestored ?? this.hasRestored,
      dismissedRestoreCard: dismissedRestoreCard ?? this.dismissedRestoreCard,
    );
  }
}

class RestoreNotifier extends Notifier<RestoreCardState> {
  SharedPreferences? _prefs;
  String? _currentUserId;

  @override
  RestoreCardState build() {
    final user = ref.watch(authStateProvider).value;
    if (user != null && !user.isAnonymous) {
      _currentUserId = user.id;
      _initPrefs(user.id);
    } else {
      _currentUserId = null;
    }
    return RestoreCardState();
  }

  Future<void> _initPrefs(String userId) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final count = _prefs?.getInt('restore_count_$userId') ?? 0;
      final restored = _prefs?.getBool('has_restored_$userId') ?? false;
      final dismissed = _prefs?.getBool('dismissed_restore_card_$userId') ?? false;

      state = RestoreCardState(
        restoreCount: count,
        hasRestored: restored,
        dismissedRestoreCard: dismissed,
      );
    } catch (_) {
      // Ignore
    }
  }

  Future<void> setRestoreCount(int count) async {
    final userId = _currentUserId;
    if (userId == null) return;
    state = state.copyWith(restoreCount: count);
    await _prefs?.setInt('restore_count_$userId', count);
  }

  Future<void> setHasRestored(bool value) async {
    final userId = _currentUserId;
    if (userId == null) return;
    state = state.copyWith(hasRestored: value);
    await _prefs?.setBool('has_restored_$userId', value);
  }

  Future<void> setDismissedRestoreCard(bool value) async {
    final userId = _currentUserId;
    if (userId == null) return;
    state = state.copyWith(dismissedRestoreCard: value);
    await _prefs?.setBool('dismissed_restore_card_$userId', value);
  }
}

final restoreNotifierProvider = NotifierProvider<RestoreNotifier, RestoreCardState>(() {
  return RestoreNotifier();
});
