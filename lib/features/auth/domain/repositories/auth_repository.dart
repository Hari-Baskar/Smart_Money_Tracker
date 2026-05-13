import 'package:expense_tracker/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> signOut();
  Future<void> signInWithGoogle();
  Future<void> updateUserName(String name);
  Future<String?> getUserName();
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> createUserWithEmailAndPassword(String email, String password);
  UserEntity? get currentUser;
  Stream<UserEntity?> get authStateChanges;
}
