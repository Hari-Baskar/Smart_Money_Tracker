import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/features/auth/domain/entities/user_entity.dart';

import 'package:smart_money_tracker/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuthRepository(this._auth, this._firestore);

  @override
  Future<void> deleteProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('profile_images')
        .child('${user.uid}.jpg');
    try {
      await ref.delete();
    } catch (e) {
      // Ignore if it doesn't exist
    }

    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': FieldValue.delete(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_photo_${user.uid}');
  }

  @override
  Future<String?> uploadProfileImage(String filePath) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final file = File(filePath);
    final ref = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('profile_images')
        .child('${user.uid}.jpg');

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
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('settings')
        .get();
    return doc.data();
  }

  @override
  Future<void> saveUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('settings')
        .set(settings, SetOptions(merge: true));
  }

  @override
  Stream<Map<String, dynamic>?> watchUserSettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('settings')
        .snapshots()
        .map((doc) => doc.data());
  }

  @override
  Future<Map<String, String?>> getUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_profile_name_${user.uid}');
      final cachedPhoto = prefs.getString('user_profile_photo_${user.uid}');
      if (cachedName != null || cachedPhoto != null) {
        return {'name': cachedName, 'photoUrl': cachedPhoto};
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final name = data['name'] as String?;
        final photoUrl = data['photoUrl'] as String?;
        await prefs.setString('user_profile_name_${user.uid}', name ?? '');
        await prefs.setString('user_profile_photo_${user.uid}', photoUrl ?? '');
        return {'name': name, 'photoUrl': photoUrl};
      }
    }
    return {'name': null, 'photoUrl': null};
  }

  @override
  Stream<Map<String, String?>> watchUserProfile(String userId) async* {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_profile_name_$userId');
    final cachedPhoto = prefs.getString('user_profile_photo_$userId');
    final cachedEmail = prefs.getString('user_profile_email_$userId');

    yield {'name': cachedName, 'photoUrl': cachedPhoto, 'email': cachedEmail};

    if (cachedName == null && cachedPhoto == null && cachedEmail == null) {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data()!;
          final name = data['name'] as String?;
          final photoUrl = data['photoUrl'] as String?;
          final email = data['email'] as String?;

          await prefs.setString('user_profile_name_$userId', name ?? '');
          await prefs.setString('user_profile_photo_$userId', photoUrl ?? '');
          await prefs.setString('user_profile_email_$userId', email ?? '');

          yield {'name': name, 'photoUrl': photoUrl, 'email': email};
        }
      } catch (e) {
        print('Error fetching profile from Firestore: $e');
      }
    }
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
      bool didReauthenticate = false;

      // If signed in with Google, reauthenticate first to prevent requires-recent-login
      for (final providerInfo in user.providerData) {
        if (providerInfo.providerId == 'google.com') {
          // Force account selection by clearing previous cached sign-in
          await _googleSignIn.signOut();
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw FirebaseAuthException(
              code: 'reauthentication-cancelled',
              message: 'Reauthentication was cancelled.',
            );
          }

          // Verify it's the same Google account
          final String? originalEmail = providerInfo.email ?? user.email;
          if (originalEmail != null && googleUser.email != originalEmail) {
            await _googleSignIn.signOut(); // Clean up the wrong sign-in
            throw FirebaseAuthException(
              code: 'user-mismatch',
              message: 'Account mismatch.',
            );
          }

          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
          didReauthenticate = true;
          break;
        }
      }

      // If they are not anonymous but didn't hit the google.com provider check, force it anyway.
      if (!didReauthenticate && !user.isAnonymous) {
        await _googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'reauthentication-cancelled',
            message: 'Reauthentication was cancelled.',
          );
        }
        final String? originalEmail = user.email;
        if (originalEmail != null && googleUser.email != originalEmail) {
          await _googleSignIn.signOut();
          throw FirebaseAuthException(
            code: 'user-mismatch',
            message: 'Account mismatch.',
          );
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        didReauthenticate = true;
      }

      // Run deletion in background
      Future.microtask(() async {
        try {
          // Frontend safeguard: manually delete the settings document to prevent old scanned_months from returning
          // if the Cloud Function is undeployed or delayed.
          try {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('profile')
                .doc('settings')
                .delete();
          } catch (_) {}

          // Delete user data from Firestore
          await _firestore.collection('users').doc(user.uid).delete();
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login' && user.isAnonymous) {
            // Safe to ignore for anonymous users. Data is deleted and Firebase cleans them up.
            await signOut();
          } else {
            print('Background deletion failed: $e');
          }
        } catch (e) {
          print('Background deletion failed: $e');
        }
      });
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

      final prefs = await SharedPreferences.getInstance();
      if (name != null) {
        await prefs.setString('user_profile_name_${user.uid}', name);
      }
      if (photoUrl != null) {
        await prefs.setString('user_profile_photo_${user.uid}', photoUrl);
      }

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
  Future<bool> signInWithGoogle() async {
    try {
      // Force account selection by clearing previous cached sign-in
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        // Pre-fill name from Google if not already set
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await prefs.setString(
            'user_profile_name_${user.uid}',
            user.displayName ?? '',
          );
          await prefs.setString(
            'user_profile_photo_${user.uid}',
            user.photoURL ?? '',
          );
          await prefs.setString(
            'user_profile_email_${user.uid}',
            user.email ?? '',
          );
        } else {
          final data = doc.data()!;
          await prefs.setString(
            'user_profile_name_${user.uid}',
            data['name'] as String? ?? '',
          );
          await prefs.setString(
            'user_profile_photo_${user.uid}',
            data['photoUrl'] as String? ?? '',
          );
          await prefs.setString(
            'user_profile_email_${user.uid}',
            data['email'] as String? ?? '',
          );
        }
      }
      return true;
    } catch (e, stackTrace) {
      print(e);
      print(e.runtimeType);

      if (e is FirebaseAuthException) {
        print("Firebase code: ${e.code}");
        print("Firebase message: ${e.message}");
      }

      print(stackTrace);
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
  Future<bool> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Force account selection by clearing previous cached sign-in
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

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

        final prefs = await SharedPreferences.getInstance();
        if (name != null)
          await prefs.setString('user_profile_name_${linkedUser.uid}', name);
        if (photoUrl != null)
          await prefs.setString(
            'user_profile_photo_${linkedUser.uid}',
            photoUrl,
          );
        if (email != null)
          await prefs.setString('user_profile_email_${linkedUser.uid}', email);
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> reAuthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final String? originalEmail = user.email;
      if (originalEmail != null && googleUser.email != originalEmail) {
        await _googleSignIn.signOut();
        throw FirebaseAuthException(
          code: 'user-mismatch',
          message: 'Account mismatch. Please select your current account.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
