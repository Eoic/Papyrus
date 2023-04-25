import 'package:client/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:client/providers/google_sign_in_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({ super.key });

  // TODO: Move to service.
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
      appBar: AppBar(title: const Text("Profile")),
      body: SafeArea(
        // child: Row(
        //   children: [
        //     Text("Signed in as ${user?.email ?? "Anonymous."}"),
        //     TextButton(
        //         onPressed: user?.email != null ? () {
        //           final userInfo = FirebaseAuth.instance.currentUser;
        //
        //           if (userInfo != null) {
        //             final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);
        //
        //             signOut(userInfo, googleProvider).then((value) {
        //               context.go("/login");
        //             });
        //           }
        //         } : null,
        //         child: const Text("Logout")
        //     )
        //   ],
        // ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    width: 128.0,
                    height: 128.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: const Image(image: AssetImage("assets/images/profile.png")),
                    ),
                  ),
                  SizedBox(height: 12.0,),
                  Text(user?.displayName ?? "Anonymous user", style: Theme.of(context).textTheme.titleLarge),
                  Text(user?.email ?? "-", style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 12.0,),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text("Edit profile")
                    )
                  ),
                  SizedBox(height: 24,),

                  ProfileButton(
                    title: "Settings",
                    icon: Icons.settings_rounded,
                    onPressed: () {},
                  ),

                  ProfileButton(
                    title: "Billing details",
                    icon: Icons.payment_rounded,
                    onPressed: () {},
                  ),

                  ProfileButton(
                    title: "Storage management",
                    icon: Icons.storage_rounded,
                    onPressed: () {},
                  ),

                  SizedBox(height: 24,),

                  ProfileButton(
                    title: "Information",
                    icon: Icons.info_rounded,
                    onPressed: () {},
                  ),

                  ProfileButton(
                    title: "Logout",
                    icon: Icons.logout_rounded,
                    onPressed: user?.email != null ? () {
                      final userInfo = FirebaseAuth.instance.currentUser;

                      if (userInfo != null) {
                        final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);

                        signOut(userInfo, googleProvider).then((value) {
                          context.go("/login");
                        });
                      }
                    } : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
