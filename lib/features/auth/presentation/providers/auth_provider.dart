import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:smart_money_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_money_tracker/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:smart_money_tracker/features/auth/presentation/state/auth_state.dart';
import 'package:smart_money_tracker/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:smart_money_tracker/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:smart_money_tracker/features/auth/presentation/notifiers/user_profile_notifier.dart';
import 'package:smart_money_tracker/features/auth/presentation/notifiers/user_name_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, UserEntity?>(
  AuthStateNotifier.new,
);

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, Map<String, String?>>(
  UserProfileNotifier.new,
);

final userNameProvider = AsyncNotifierProvider<UserNameNotifier, String?>(
  UserNameNotifier.new,
);
