import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class UserProfileNotifier extends AsyncNotifier<Map<String, String?>> {
  StreamSubscription<Map<String, String?>>? _subscription;

  @override
  FutureOr<Map<String, String?>> build() async {
    final authStateAsync = ref.watch(authStateProvider);
    final authState = authStateAsync.value;

    if (authState == null) {
      return {'name': null, 'photoUrl': null};
    }

    final repository = ref.watch(authRepositoryProvider);
    
    _subscription?.cancel();
    final stream = repository.watchUserProfile(authState.id).map((profile) => {
      ...profile,
      'isAnonymous': authState.isAnonymous ? 'true' : 'false',
    });

    final completer = Completer<Map<String, String?>>();

    _subscription = stream.listen(
      (profile) {
        if (!completer.isCompleted) {
          completer.complete(profile);
        }
        state = AsyncData(profile);
      },
      onError: (err, stack) {
        if (!completer.isCompleted) {
          completer.completeError(err, stack);
        }
        state = AsyncError(err, stack);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete({'name': null, 'photoUrl': null});
        }
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return completer.future;
  }
}
