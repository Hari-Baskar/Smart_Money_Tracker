import 'package:smart_money_tracker/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<bool> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<bool> linkWithGoogle();
  Future<String?> uploadProfileImage(String filePath);
  Future<void> updateProfile({String? name, String? photoUrl});
  Future<Map<String, String?>> getUserProfile();
  Stream<Map<String, String?>> watchUserProfile(String userId);
  UserEntity? get currentUser;
  Stream<UserEntity?> get authStateChanges;
}
