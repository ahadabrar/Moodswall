import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<T> safeExecute<T>(Future<T> Function() action, {String errorMessage = 'An error occurred'}) async {
  try {
    return await action();
  } on FirebaseAuthException catch (e) {
    debugPrint('$errorMessage: ${e.message}');
    rethrow;
  } catch (e) {
    debugPrint('$errorMessage: $e');
    rethrow;
  }
}
