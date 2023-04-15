import 'package:client/providers/google_sign_in_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({ super.key });

  Future signOut(User userInfo, GoogleSignInProvider provider) async {
    for (var userInfo in userInfo.providerData) {
      if (userInfo.providerId == "google.com") {
        return provider.signOutWithGoogle();
      }
    }

    return FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text("Signed in as ${user?.email}"),
            ElevatedButton(
              onPressed: () {
                final userInfo = FirebaseAuth.instance.currentUser;

                if (userInfo != null) {
                  final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);

                  signOut(userInfo, googleProvider).then((value) {
                    Navigator.pushNamed(context, "/login");
                  });
                }
              },
              child: const Text("Logout")
            )
          ],
        ),
      ),
    );
  }
}
