import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  bool _initialized = false;
  late final StreamSubscription<AuthState> _authSubscription;

  User? _user;
  User? get user => _user;

  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AuthProvider() {
    // Listen to Supabase auth state changes
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });

    // Initialize Google Sign-In (not needed on web, where Supabase OAuth handles it)
    if (!kIsWeb) {
      _initGoogleSignIn();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
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
            // Google signed out; Supabase auth state listener handles state update
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
      unawaited(
        GoogleSignIn.instance.attemptLightweightAuthentication()?.then((
          account,
        ) async {
          if (account != null) {
            await _handleGoogleSignInEvent(account);
          }
        }),
      );
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  Future<void> _handleGoogleSignInEvent(GoogleSignInAccount account) async {
    try {
      final idToken = account.authentication.idToken;

      if (idToken != null) {
        final response = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
        _user = response.user;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Supabase credential sign-in error: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Web: redirect to Google OAuth via Supabase; user is set via onAuthStateChange after return
        await _client.auth.signInWithOAuth(OAuthProvider.google);
      } else {
        // Mobile/Desktop: use google_sign_in for native dialog, exchange token with Supabase
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
          final GoogleSignInAccount account =
              await GoogleSignIn.instance.authenticate();

          final idToken = account.authentication.idToken;

          if (idToken != null) {
            final response = await _client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
            );
            _user = response.user;
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return _user;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      debugPrint('Supabase Auth Error: ${e.message}');
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
      await _client.auth.signOut();

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
