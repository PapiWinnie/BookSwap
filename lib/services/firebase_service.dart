// fixed warning: use debugPrint instead of print for production-safe logging
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await credential.user?.sendEmailVerification();

      // Create user document
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        emailVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      // fixed warning: replaced print with debugPrint
      debugPrint('✅ User document created for: ${credential.user!.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ SignUp Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ SignUp Error: $e');
      rethrow;
    }
  }

  // Sign in - AUTO-CREATES USER DOCUMENT IF MISSING
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // fixed warning: replaced print with debugPrint
      debugPrint('✅ Signed in: ${credential.user!.uid}');

      // Check if user document exists, create if missing
      var userData = await getUserData(credential.user!.uid);

      if (userData == null) {
        // fixed warning: replaced print with debugPrint
        debugPrint('⚠️ User document missing - creating now...');

        // Create missing user document
        userData = UserModel(
          id: credential.user!.uid,
          email: credential.user!.email!,
          name: credential.user!.email!.split(
            '@',
          )[0], // Use email prefix as name
          emailVerified: credential.user!.emailVerified,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData.toMap());

        // fixed warning: replaced print with debugPrint
        debugPrint('✅ User document created on login');
      }

      return userData;
    } on FirebaseAuthException catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ SignIn Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ SignIn Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // fixed warning: replaced print with debugPrint
      debugPrint('✅ Signed out');
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ SignOut Error: $e');
      rethrow;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      // fixed warning: replaced print with debugPrint
      debugPrint('🔍 Fetching user data for: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      // fixed warning: replaced print with debugPrint
      debugPrint('📄 Document exists: ${doc.exists}');
      // fixed warning: replaced print with debugPrint
      debugPrint('📄 Document data: ${doc.data()}');

      if (doc.exists && doc.data() != null) {
        final userData = UserModel.fromMap(doc.data()!);
        // fixed warning: replaced print with debugPrint
        debugPrint('✅ User data loaded: ${userData.name} (${userData.email})');
        return userData;
      }

      // fixed warning: replaced print with debugPrint
      debugPrint('⚠️ No user document found for: $userId');
      return null;
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ getUserData Error: $e');
      rethrow;
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      // fixed warning: replaced print with debugPrint
      debugPrint('✅ Verification email sent');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception('Too many requests. Please wait before trying again.');
      }
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ Resend verification error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Reload user (to check verification status)
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      // fixed warning: replaced print with debugPrint
      debugPrint('✅ User reloaded');
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('⚠️ Reload user error: $e');
      // Silently fail - user might have been signed out
    }
  }

  // Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': user.emailVerified,
        });
        // fixed warning: replaced print with debugPrint
        debugPrint('✅ Email verification status updated');
      }
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ Error updating verification status: $e');
    }
  }
}
