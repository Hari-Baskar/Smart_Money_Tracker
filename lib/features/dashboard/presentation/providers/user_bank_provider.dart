import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/user_bank_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
final userBankRepositoryProvider = Provider<UserBankRepository>((ref) {
  return UserBankRepository(FirebaseFirestore.instance);
});

// ── User Bank IDs Provider (local-first, async) ───────────────────────────────
/// Returns the list of bank IDs the user has actually used.
/// Reads from SharedPreferences first; falls back to Firestore if empty.
final userBankIdsProvider = FutureProvider<List<String>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;

  if (userId == null) return [];

  final repo = ref.read(userBankRepositoryProvider);
  return repo.getUserBankIds(userId);
});
