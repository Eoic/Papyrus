import 'package:client/providers/google_sign_in_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
        child: Row(
          children: [
            Text("Signed in as ${user?.email ?? "Anonymous."}"),
            TextButton(
              onPressed: user?.email != null ? () {
                final userInfo = FirebaseAuth.instance.currentUser;

                if (userInfo != null) {
                  final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);

                  signOut(userInfo, googleProvider).then((value) {
                    // Navigator.pushNamed(context, "/login");
                    context.go("/login");
                  });
                }
              } : null,
              child: const Text("Logout")
            )
          ],
        ),
      ),
    );
  }
}
