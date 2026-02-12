import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  User? _user;
  User? get user => _user;

  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  GoogleSignInProvider() {
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });

    // Initialize Google Sign-In and listen to its events (not needed on web,
    // where Firebase Auth's signInWithPopup is used directly)
    if (!kIsWeb) {
      _initGoogleSignIn();
    }
  }

  Future<void> _initGoogleSignIn() async {
    if (_initialized) return;

    try {
      await GoogleSignIn.instance.initialize();
      _initialized = true;

      // Listen to Google Sign-In authentication events
      GoogleSignIn.instance.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            await _handleGoogleSignInEvent(event.user);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            // Google signed out, but Firebase auth state listener handles this
          }
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
          debugPrint('Google Sign-In Stream Error: $error');
        },
      );

      // Attempt lightweight authentication (silent sign-in)
      if (!kIsWeb) {
        unawaited(
          GoogleSignIn.instance.attemptLightweightAuthentication()?.then((
            account,
          ) async {
            if (account != null) {
              await _handleGoogleSignInEvent(account);
            }
          }),
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  Future<void> _handleGoogleSignInEvent(GoogleSignInAccount account) async {
    try {
      final idToken = account.authentication.idToken;

      if (idToken != null) {
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Firebase credential sign-in error: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Web sign-in flow uses Firebase directly with popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );
        _user = userCredential.user;
      } else {
        // Mobile/Desktop sign-in flow
        await _initGoogleSignIn();

        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          // Platform doesn't support authenticate(), rely on lightweight auth
          final account = await GoogleSignIn.instance
              .attemptLightweightAuthentication();
          if (account != null) {
            await _handleGoogleSignInEvent(account);
          } else {
            _error = 'Sign-in not available on this platform';
          }
        } else {
          // Use full authenticate flow
          final GoogleSignInAccount account = await GoogleSignIn.instance
              .authenticate();

          final idToken = account.authentication.idToken;

          if (idToken != null) {
            final OAuthCredential credential = GoogleAuthProvider.credential(
              idToken: idToken,
            );

            final UserCredential userCredential = await _auth
                .signInWithCredential(credential);
            _user = userCredential.user;
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return _user;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } on GoogleSignInException catch (e) {
      // Handle user cancellation gracefully
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _error = null; // Don't show error for user cancellation
      } else {
        _error = e.description ?? e.code.toString();
      }
      _isLoading = false;
      notifyListeners();
      debugPrint('Google Sign-In Error: ${e.code} - ${e.description}');
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();

      if (!kIsWeb && _initialized) {
        await GoogleSignIn.instance.signOut();
      }

      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Sign-Out Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
