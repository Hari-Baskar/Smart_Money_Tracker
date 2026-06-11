import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/user_bank_repository.dart';
import '../notifiers/user_bank_ids_notifier.dart';
import 'datasource_provider.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
final userBankRepositoryProvider = Provider<UserBankRepository>((ref) {
  final local = ref.watch(dashboardLocalDataSourceProvider);
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return UserBankRepository(local, remote);
});

// ── User Bank IDs Provider (local-first, async) ───────────────────────────────
/// Returns the list of bank IDs the user has actually used.
/// Reads from SharedPreferences first; falls back to Firestore if empty.
final userBankIdsProvider = AsyncNotifierProvider<UserBankIdsNotifier, List<String>>(() {
  return UserBankIdsNotifier();
});
