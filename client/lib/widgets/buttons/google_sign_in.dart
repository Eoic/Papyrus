import 'package:client/providers/google_sign_in_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GoogleSignInButton extends StatefulWidget {
  final String title;

  const GoogleSignInButton({super.key, required this.title});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: isSigningIn
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
          : OutlinedButton(
              style: ButtonStyle(
                side: const WidgetStatePropertyAll<BorderSide>(
                  BorderSide(width: 1.0, color: Colors.grey),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              onPressed: () async {
                setState(() => isSigningIn = true);
                final provider =
                    Provider.of<GoogleSignInProvider>(context, listen: false);

                provider.signInWithGoogle().then((value) {
                  if (value != null) {
                    context.goNamed('LIBRARY');
                  }
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    duration: const Duration(seconds: 5),
                    content:
                        const Text("Failed to sign in with Google account."),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ));
                });

                setState(() => isSigningIn = false);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Image(
                      image: AssetImage("assets/images/google_logo.png"),
                      height: 35.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(widget.title,
                          style: Theme.of(context).textTheme.titleMedium),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
