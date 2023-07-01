import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;
  GoogleSignInAccount get user => _user!;

  Future signInWithGoogle() async {
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return null;
    }

    _user = googleUser;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken
    );

    return FirebaseAuth.instance.signInWithCredential(credential).then((user) {
      notifyListeners();
      return user;
    });
  }

  Future signOutWithGoogle() async {
    FirebaseAuth.instance.signOut();
    return await googleSignIn.signOut();
  }
}