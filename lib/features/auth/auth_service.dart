import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moodwalls/core/firestore_service.dart';
import 'package:moodwalls/features/auth/user_model.dart';
import 'package:moodwalls/core/error_handler.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserModel?> signUp(String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase(), 
        password: password
      );
      User? user = result.user;

      if (user != null) {

        final isAdmin = email.toLowerCase() == 'moodswalladmin@gmail.com';
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          username: username,
          preferredMood: 'Happy',
          isAdmin: isAdmin,
        );
        try {
          final collection = isAdmin ? 'admins' : 'users';
          await _firestore.collection(collection).doc(user.uid).set(newUser.toMap());
        } catch (firestoreError) {
          debugPrint('Firestore Error: $firestoreError');

          debugPrint('User created in Firebase Auth but failed to save to Firestore');
          rethrow;
        }
        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint('Sign up error: The email address is already in use by another account.');
        throw 'The email address is already in use. If you deleted your profile earlier, please Login instead to restore your account.';
      }
      debugPrint('Sign up error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<User?> login(String email, String password) async {
    return safeExecute(
      () async {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.toLowerCase(), 
          password: password,
        );
        return result.user;
      },
      errorMessage: 'Login failed',
    );
  }

  Future<User?> signInWithGoogle() async {
    return safeExecute(
      () async {
        if (kIsWeb) {
          GoogleAuthProvider googleProvider = GoogleAuthProvider();
          final userCredential = await _auth.signInWithPopup(googleProvider);
          final user = userCredential.user;
          if (user != null) {
            await _createUserDocument(user);
          }
          return user;
        }

        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null || googleAuth.accessToken == null) {
          throw FirebaseAuthException(
            code: 'ERROR_MISSING_GOOGLE_AUTH_TOKEN',
            message: 'Missing Google authentication tokens.',
          );
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential result = await _auth.signInWithCredential(credential);
        final user = result.user;
        if (user != null) {
          await _createUserDocument(user);
        }
        return user;
      },
      errorMessage: 'Google Sign-In failed',
    );
  }

  Future<void> _createUserDocument(User user) async {
    final isAdmin = (user.email ?? '').toLowerCase() == 'moodswalladmin@gmail.com';
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      username: user.displayName ?? user.email?.split('@').first ?? 'Google User',
      preferredMood: 'Happy',
      isAdmin: isAdmin,
    );
    final collection = isAdmin ? 'admins' : 'users';
    await _firestore.collection(collection).doc(user.uid).set(
      userModel.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<User?> adminCreateUser(String email, String password, String username) async {
    // To create a user without logging out the current admin, 
    // we must use a secondary Firebase app instance.
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'AdminUserCreator',
      options: Firebase.app().options,
    );

    try {
      UserCredential result = await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await FirestoreService().createUserRecord(
          uid: user.uid,
          email: email,
          username: username,
        );
        return user;
      }
      return null;
    } finally {
      // Always delete the secondary app to clean up resources
      await secondaryApp.delete();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> changePassword(String email, String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      final credential = EmailAuthProvider.credential(email: email, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } else {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: oldPassword);
      await result.user?.updatePassword(newPassword);
    }
  }
}
