import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static bool _googleReady = false;

  static Future<void> signInEmail(String email, String pass) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: pass);

  static Future<void> signUpEmail(String email, String pass) =>
      _auth.createUserWithEmailAndPassword(email: email.trim(), password: pass);

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static Future<void> signInGoogle() async {
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
    }
    final acct = await GoogleSignIn.instance.authenticate();
    final cred =
        GoogleAuthProvider.credential(idToken: acct.authentication.idToken);
    await _auth.signInWithCredential(cred);
  }

  static bool get appleAvailable => Platform.isIOS;

  static Future<void> signInApple() async {
    final raw = _nonce();
    final hashed = sha256.convert(utf8.encode(raw)).toString();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashed,
    );
    final cred = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: raw,
    );
    await _auth.signInWithCredential(cred);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  static Future<void> deleteAccount() async => _auth.currentUser?.delete();

  static String _nonce([int len = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email does not look right.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'This email already has an account.';
        case 'weak-password':
          return 'Password must have 6 or more letters.';
        case 'network-request-failed':
          return 'No internet. Try again.';
      }
      return e.message ?? 'Sign in failed.';
    }
    return 'Sign in failed. Try again.';
  }
}
