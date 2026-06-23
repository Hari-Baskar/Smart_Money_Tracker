import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/user_bank_provider.dart';

class UserBankIdsNotifier extends AsyncNotifier<List<String>> {
  @override
  FutureOr<List<String>> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;

    if (userId == null) return [];

    final repo = ref.read(userBankRepositoryProvider);
    return await repo.getUserBankIds(userId);
  }
}
