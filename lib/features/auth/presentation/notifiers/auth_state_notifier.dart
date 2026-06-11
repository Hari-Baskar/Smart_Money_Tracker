import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class AuthStateNotifier extends AsyncNotifier<UserEntity?> {
  StreamSubscription<UserEntity?>? _subscription;

  @override
  FutureOr<UserEntity?> build() {
    final repository = ref.watch(authRepositoryProvider);
    
    _subscription?.cancel();
    _subscription = repository.authStateChanges.listen((user) async {
      state = AsyncData(user);
      try {
        final prefs = await SharedPreferences.getInstance();
        if (user != null) {
          await prefs.setString('current_user_uid', user.id);
        } else {
          await prefs.remove('current_user_uid');
        }
      } catch (e) {
        print('Error saving user UID to SharedPreferences: $e');
      }
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Also populate SharedPreferences for the initial currentUser synchronously if available
    final current = repository.currentUser;
    if (current != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('current_user_uid', current.id);
      }).catchError((e) {
        print('Error setting initial UID: $e');
      });
    }

    return current;
  }
}

