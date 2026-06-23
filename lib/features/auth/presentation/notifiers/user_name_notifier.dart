import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class UserNameNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    final profile = await ref.watch(userProfileProvider.future);
    return profile['name'];
  }
}
