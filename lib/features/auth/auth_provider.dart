// keeps track of the logged in user state and handles signup login and logout
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodwalls/features/auth/user_model.dart';
import 'package:moodwalls/features/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  UserModel? _userModel;

  User? get user => _firebaseUser;
  UserModel? get userModel => _userModel;

  Stream<User?> get authStateChanges => _authService.user;

  AuthProvider() {
    _authService.user.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  void _fetchUserData(String uid) {
    _userSubscription?.cancel();

    // check collection based on user email
    final email = (_firebaseUser?.email ?? '').toLowerCase();
    final collection = email == 'moodswalladmin@gmail.com' ? 'admins' : 'users';

    _userSubscription = FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              _userModel = UserModel.fromMap(data, uid);
            } else {
              _userModel = null;
            }
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error looking up user stream in $collection: $e");
          },
        );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    await _authService.login(email, password);
  }

  Future<User?> signInWithGoogle() async {
    return await _authService.signInWithGoogle();
  }

  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> signUp(String email, String password, String username) async {
    await _authService.signUp(email, password, username);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> changePassword(
    String email,
    String oldPassword,
    String newPassword,
  ) async {
    await _authService.changePassword(email, oldPassword, newPassword);
  }

  Future<void> adminCreateUser(
    String email,
    String password,
    String username,
  ) async {
    await _authService.adminCreateUser(email, password, username);
  }
}
