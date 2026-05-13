import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_generator/constants/app_translations.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.'.tr;
      case 'email-already-in-use':
        return 'An account already exists for that email.'.tr;
      case 'invalid-email':
        return 'The email address is invalid.'.tr;
      case 'user-not-found':
        return 'No user found for that email.'.tr;
      case 'wrong-password':
        return 'Wrong password provided.'.tr;
      case 'user-disabled':
        return 'This user account has been disabled.'.tr;
      case 'too-many-requests':
        return 'Too many requests. Please try again later.'.tr;
      case 'operation-not-allowed':
        return 'This operation is not allowed.'.tr;
      default:
        return e.message ?? 'An unknown error occurred.'.tr;
    }
  }
}
