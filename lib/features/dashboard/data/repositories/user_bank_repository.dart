import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';

class UserBankRepository {
  final FirebaseFirestore _firestore;
  static const String _localKey = 'user_bank_ids';

  UserBankRepository(this._firestore);

  // ── 1. GET: Local-first, fallback to Firestore ──────────────────────────────
  Future<List<String>> getUserBankIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getStringList(_localKey);

    // Return local cache immediately if it's populated
    if (local != null && local.isNotEmpty) {
      return local;
    }

    // Local is empty → try Firestore
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('settings')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final remote = List<String>.from(data?['userBankIds'] ?? []);
        if (remote.isNotEmpty) {
          // Cache it locally for next time
          await prefs.setStringList(_localKey, remote);
          return remote;
        }
      }
    } catch (e) {
      // Firestore unavailable — return empty, the UI will handle it gracefully
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localKey, validIds);

    // Remote save (fire-and-forget; don't await in hot path)
    _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('settings')
        .set({'userBankIds': validIds}, SetOptions(merge: true)).catchError(
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

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_localKey) ?? [];

    if (!current.contains(bankId)) {
      final updated = [...current, bankId];
      await updateUserBankIds(userId, updated);
    }
  }

  // ── 4. Derive bank IDs from existing transactions (one-time bootstrap) ──────
  Future<List<String>> _deriveAndSaveBankIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      final bankIds = snapshot.docs
          .map((doc) => doc.data()['bankId'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey);
  }
}
