import 'package:client/pages/library_page.dart';
import 'package:client/pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({ super.key });

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return const LibraryPage();
    }

    return const WelcomePage();
  }
}