import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:smart_money_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_money_tracker/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:smart_money_tracker/core/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
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
      state = const AsyncData(null);
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
        state = const AsyncData(null);
        return true;
      } else {
        state = const AsyncData(null);
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
      state = const AsyncData(null);
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
        
        state = const AsyncData(null);

        // Force Riverpod to re-read everything immediately
        ref.invalidate(authStateProvider);
        ref.invalidate(userProfileProvider);
        return true;
      } else {
        state = const AsyncData(null);
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    await _clearLocalCacheAndProviders();
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.deleteAccount();
      await _clearLocalCacheAndProviders();
      state = const AsyncData(null);
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

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

final userProfileProvider = StreamProvider<Map<String, String?>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final authState = authStateAsync.value;
  
  if (authState == null) {
    return Stream.value({'name': null, 'photoUrl': null});
  }
  
  // Real-time stream from Firestore (both guest/anonymous and registered users use Firestore)
  final repository = ref.read(authRepositoryProvider);
  return repository.watchUserProfile(authState.id).map((profile) => {
    ...profile,
    'isAnonymous': authState.isAnonymous ? 'true' : 'false',
  });
});

final userNameProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile['name'];
});
