import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/widgets/profile_button.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // TODO: Move to service.
  Future signOut(User userInfo, GoogleSignInProvider provider) async {
    for (var userInfo in userInfo.providerData) {
      if (userInfo.providerId == "google.com") {
        return provider.signOutWithGoogle();
      }
    }

    return FirebaseAuth.instance.signOut();
  }
  // ---

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SafeArea(
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
                      borderRadius: BorderRadius.circular(10),
                      child: FirebaseAuth.instance.currentUser?.photoURL != null
                          ? Image.network(
                              FirebaseAuth.instance.currentUser!.photoURL
                                  as String,
                              scale: 0.7,
                            )
                          : const Image(
                              image: AssetImage('assets/images/profile.png'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    user?.displayName ?? "Anonymous user",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    (user?.email == null || user?.email?.trim() == '')
                        ? 'No email provided.'
                        : '-',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text("Edit profile"),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  // E-ink mode toggle for testing
                  Consumer<DisplayModeProvider>(
                    builder: (context, displayMode, child) {
                      return SwitchListTile(
                        title: const Text('E-ink Display Mode'),
                        subtitle: Text(
                          displayMode.isEinkMode
                              ? 'High contrast mode active'
                              : 'Standard display mode',
                        ),
                        secondary: Icon(
                          displayMode.isEinkMode
                              ? Icons.tablet_android
                              : Icons.phone_android,
                        ),
                        value: displayMode.isEinkMode,
                        onChanged: (_) => displayMode.toggleEinkMode(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ProfileButton(
                    title: "Information",
                    icon: Icons.info_rounded,
                    onPressed: () {},
                  ),
                  ProfileButton(
                    title: "Logout",
                    icon: Icons.logout_rounded,
                    onPressed: () {
                      final userInfo = FirebaseAuth.instance.currentUser;

                      if (userInfo != null) {
                        final googleProvider =
                            Provider.of<GoogleSignInProvider>(
                              context,
                              listen: false,
                            );

                        signOut(userInfo, googleProvider).then((value) {
                          context.go("/login");
                        });
                      }
                    },
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
