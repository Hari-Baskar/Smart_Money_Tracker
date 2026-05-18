import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:smart_money_tracker/features/auth/domain/entities/user_entity.dart';

import 'package:smart_money_tracker/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuthRepository(this._auth, this._firestore);

  @override
  Future<String?> uploadProfileImage(String filePath) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final file = File(filePath);
    final ref = _storage.ref().child('profile_images').child('${user.uid}.jpg');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.userChanges().map((user) {
      if (user == null) return null;
      return UserEntity(id: user.uid, isAnonymous: user.isAnonymous);
    });
  }

  @override
  UserEntity? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserEntity(id: user.uid, isAnonymous: user.isAnonymous);
  }

  @override
  Future<Map<String, String?>> getUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'name': data['name'] as String?,
          'photoUrl': data['photoUrl'] as String?,
        };
      }
    }
    return {'name': null, 'photoUrl': null};
  }

  @override
  Stream<Map<String, String?>> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'name': data['name'] as String?,
          'photoUrl': data['photoUrl'] as String?,
          'email': data['email'] as String?,
        };
      }
      return {'name': null, 'photoUrl': null, 'email': null};
    });
  }

  @override
  Future<String?> getUserName() async {
    final profile = await getUserProfile();
    return profile['name'];
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user transactions
      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in transactions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await user.delete();
    }
  }

  @override
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user != null) {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      // Also update Firebase Auth profile for consistency
      if (name != null || photoUrl != null) {
        await user.updateDisplayName(name ?? user.displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
      }
    }
  }

  @override
  Future<void> updateUserName(String name) async {
    await updateProfile(name: name);
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Pre-fill name from Google if not already set
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential to the current user
      final userCredential = await user.linkWithCredential(credential);
      final linkedUser = userCredential.user;

      if (linkedUser != null) {
        // Use data from either the linkedUser or the Google credential itself
        final String? name = linkedUser.displayName ?? googleUser.displayName;
        final String? email = linkedUser.email ?? googleUser.email;
        final String? photoUrl = linkedUser.photoURL ?? googleUser.photoUrl;

        // Update user profile in Firestore
        await _firestore.collection('users').doc(linkedUser.uid).set({
          'name': name,
          'email': email,
          'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }
}
