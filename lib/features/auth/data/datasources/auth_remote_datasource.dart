import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

class AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final Logger _logger = AppLogger.getLogger('AuthRemoteDataSource');
  StreamSubscription<GoogleSignInAuthenticationEvent>?
      _authenticationSubscription;

  AuthRemoteDataSource({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn {
    unawaited(_googleSignIn.initialize().then((value) {
      _authenticationSubscription =
          _googleSignIn.authenticationEvents.listen(_handleAuthenticationEvent);
      // Note: attemptLightweightAuthentication() is intentionally not called here
      // to prevent automatic sign-in. Users must explicitly sign in via signInWithGoogle()
    }));
  }
  Future<void> _handleAuthenticationEvent(
      GoogleSignInAuthenticationEvent event) async {
    _logger.info('Authentication event: $event');
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn user:
        _logger.info('Authentication event: signedIn');
        final GoogleSignInAccount googleUser = user.user;
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        try {
          final credential = firebase_auth.GoogleAuthProvider.credential(
              idToken: googleAuth.idToken);
          final userCredential =
              await _firebaseAuth.signInWithCredential(credential);
          _logger
              .info('signInWithGoogle: Success - ${userCredential.user?.uid}');
        } catch (e, stackTrace) {
          _logger.severe(
              'signInWithGoogle: Failure - ${e.toString()}', e, stackTrace);
          await _firebaseAuth.signOut();
          rethrow;
        }
        break;
      case GoogleSignInAuthenticationEventSignOut():
        _logger.info('Authentication event: signedOut');
        await _firebaseAuth.signOut();
        break;
    }
  }

  Future<void> signInWithGoogle() async {
    _logger.info('signInWithGoogle: Entry');

    try {
      // Sign out from Google Sign-In first to ensure a clean authentication flow
      // This prevents re-authentication issues with existing accounts
      try {
        await _googleSignIn.signOut();
        _logger
            .info('signInWithGoogle: Cleared existing Google Sign-In session');
      } catch (e) {
        // Ignore errors when signing out (might not be signed in)
        _logger.info('signInWithGoogle: No existing session to clear');
      }

      // Authenticate with Google Sign-In
      // This will show the account picker or sign-in UI
      // Note: authenticate() throws GoogleSignInException if canceled or fails
      final googleUser =
          await _googleSignIn.authenticate(scopeHint: ['email', 'profile']);

      _logger.info('signInWithGoogle: Success - ${googleUser.email}');
      // Note: The actual Firebase sign-in happens via _handleAuthenticationEvent
      // which is triggered by the authenticationEvents stream
    } on GoogleSignInException catch (e) {
      // Handle Google Sign-In specific errors
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _logger.info('signInWithGoogle: User canceled sign-in');
        // Don't rethrow cancellation - it's expected user behavior
        return;
      } else {
        _logger.severe('signInWithGoogle: Google Sign-In error - ${e.code}', e,
            StackTrace.current);
        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.severe('signInWithGoogle: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _logger.info('signOut: Entry');

    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
      _logger.info('signOut: Success');
    } catch (e, stackTrace) {
      _logger.severe('signOut: Failure', e, stackTrace);
      rethrow;
    }
  }

  Stream<firebase_auth.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  Future<String?> getAuthToken() async {
    _logger.info('getAuthToken: Entry');

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _logger.info('getAuthToken: No current user');
        return null;
      }

      final token = await user.getIdToken();
      _logger.info('getAuthToken: Success');
      return token;
    } catch (e, stackTrace) {
      _logger.severe('getAuthToken: Failure', e, stackTrace);
      rethrow;
    }
  }

  void dispose() {
    _authenticationSubscription?.cancel();
    _authenticationSubscription = null;
  }
}
