import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/services/fcm_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/auth/presentation/state/auth_state.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/datasources/dashboard_local_data_source.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    return AuthState();
  }

  Future<String?> uploadProfileImage(String filePath) async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.uploadProfileImage(filePath);
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updateProfile(name: name, photoUrl: photoUrl);
      state = AsyncData(AuthState(isSuccess: true));
      ref.invalidate(userProfileProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, String?>> getUserProfile() async {
    final repository = ref.read(authRepositoryProvider);
    return repository.getUserProfile();
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.signInWithGoogle();
      if (success) {
        await FCMService.initialize();
        state = AsyncData(AuthState(isSuccess: true));
        return true;
      } else {
        state = AsyncData(AuthState(isSuccess: false));
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInAnonymously();
      await FCMService.initialize();
      state = AsyncData(AuthState(isSuccess: true));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> linkWithGoogle() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.linkWithGoogle();
      
      if (success) {
        // Force reload the user to refresh local profile data
        await FirebaseAuth.instance.currentUser?.reload();
        await FCMService.initialize();
        
        state = AsyncData(AuthState(isSuccess: true));

        // Force Riverpod to re-read everything immediately
        ref.invalidate(authStateProvider);
        ref.invalidate(userProfileProvider);
        return true;
      } else {
        state = AsyncData(AuthState(isSuccess: false));
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    final currentUser = repository.currentUser;
    
    if (currentUser != null && !currentUser.isAnonymous) {
      try {
        await repository.saveUserSettings(currentUser.id, {
          'active_device_id': FieldValue.delete(),
          'active_device_name': FieldValue.delete(),
        });
      } catch (e) {
        print('Error clearing device info on logout: $e');
      }
    }

    await repository.signOut();
    await _clearLocalCacheAndProviders();
  }

  Future<void> forceSignOut(String uid) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    await _clearLocalCacheAndProviders();
    
    // Completely clear the local SQLite database for safety
    final localDb = DashboardLocalDataSource();
    await localDb.clearDatabase(uid);
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.deleteAccount();
      await _clearLocalCacheAndProviders();
      state = AsyncData(AuthState(isSuccess: true));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> _clearLocalCacheAndProviders() async {
    try {
      // 1. Clear SharedPreferences local storage/cache completely
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. Invalidate state providers so they clean up and refresh
      ref.invalidate(userProfileProvider);
      ref.invalidate(userNameProvider);
      ref.invalidate(subcategoriesProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(transactionSyncProvider);
    } catch (e) {
      print('Error clearing local cache and resetting providers: $e');
    }
  }
}
