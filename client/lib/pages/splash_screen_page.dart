import 'package:client/pages/library_page.dart';
import 'package:client/pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// https://www.youtube.com/watch?v=4vKiJZNPhss
class SplashScreenPage extends StatelessWidget {
  SplashScreenPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                Navigator.pushNamed(context, '/library');
              });
            }

            return WelcomePage();
          },
      ),
    );
  }
}