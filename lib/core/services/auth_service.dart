import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  User? get currentUser => _auth.currentUser;

  // Update user name in Firestore
  Future<void> updateUserName(String name) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get user name from Firestore
  Future<String?> getUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['name'] as String?;
      }
    }
    return null;
  }
}
