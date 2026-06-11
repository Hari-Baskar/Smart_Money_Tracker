import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

class UserBankRepository {
  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _remoteDataSource;
  static const String _localKey = 'user_bank_ids';

  UserBankRepository(this._localDataSource, this._remoteDataSource);

  // ── 1. GET: Local-first, fallback to Firestore ──────────────────────────────
  Future<List<String>> getUserBankIds(String userId) async {
    final local = await _localDataSource.getStringList(_localKey);

    // Return local cache immediately if it's populated
    if (local != null && local.isNotEmpty) {
      return local;
    }

    // Local is empty → try Firestore
    try {
      final remote = await _remoteDataSource.getUserBankIds(userId);
      if (remote.isNotEmpty) {
        // Cache it locally for next time
        await _localDataSource.setStringList(_localKey, remote);
        return remote;
      }
    } catch (e) {
      // Firestore unavailable — return empty
    }

    // Nothing found — derive from existing transactions
    return _deriveAndSaveBankIds(userId);
  }

  // ── 2. UPDATE: Write to both local + Firestore ──────────────────────────────
  Future<void> updateUserBankIds(String userId, List<String> bankIds) async {
    // Validate: only keep IDs that exist in our master bank list
    final validIds = bankIds
        .where(
          (id) => PaymentConstants.indianBanks.any((b) => b.id == id),
        )
        .toSet()
        .toList();

    // Local save (always, even offline)
    await _localDataSource.setStringList(_localKey, validIds);

    // Remote save (fire-and-forget; don't await in hot path)
    _remoteDataSource.saveUserBankIds(userId, validIds).catchError(
      (e) {
        // Non-critical — local cache is the primary store
      },
    );
  }

  // ── 3. Add a single bank to the user's list (called on each transaction save)
  Future<void> addBankId(String userId, String bankId) async {
    if (bankId.isEmpty) return;

    // Only add if it's a recognised bank
    final isKnown = PaymentConstants.indianBanks.any((b) => b.id == bankId);
    if (!isKnown) return;

    final current = await _localDataSource.getStringList(_localKey) ?? [];

    if (!current.contains(bankId)) {
      final updated = [...current, bankId];
      await updateUserBankIds(userId, updated);
    }
  }

  // ── 4. Derive bank IDs from existing transactions (one-time bootstrap) ──────
  Future<List<String>> _deriveAndSaveBankIds(String userId) async {
    try {
      final bankIds = await _remoteDataSource.deriveBankIdsFromTransactions(userId);
      if (bankIds.isNotEmpty) {
        await updateUserBankIds(userId, bankIds);
      }
      return bankIds;
    } catch (e) {
      return [];
    }
  }

  // ── 5. Clear local cache (e.g. on sign-out) ─────────────────────────────────
  Future<void> clearLocalCache() async {
    await _localDataSource.remove(_localKey);
  }
}
