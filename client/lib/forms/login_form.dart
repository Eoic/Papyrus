import 'package:client/widgets/input/email_input.dart';
import 'package:client/widgets/input/password_input.dart';
import 'package:client/widgets/titled_divider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/buttons/google_sign_in.dart';
import 'package:go_router/go_router.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({ super.key });

  @override
  State<LoginForm> createState() => _LoginForm();
}

class _LoginForm extends State<LoginForm> {
  bool isLoginDisabled = false;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(text: "karolis.strazdas@pm.me");
  final passwordController = TextEditingController(text: "kaunas123");

  Future<UserCredential> signIn() async {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim()
    ).then((UserCredential user) {
      return user;
    }).catchError((error) async {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text("Incorrect username or password."),
          backgroundColor: Theme.of(context).colorScheme.error,
        )
      );

      return error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sign in",
                style: Theme.of(context).textTheme.headlineMedium
              ),
            ),
            const SizedBox(height: 16),
            EmailInput(
              labelText: "Email address",
              controller: emailController,
            ),
            const SizedBox(height: 24),
            PasswordInput(
              labelText: "Password",
              controller: passwordController,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("Forgot your password?"),
              ),
            ),
            ElevatedButton(
              onPressed: isLoginDisabled ? null : () async {
                if (formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  setState(() => isLoginDisabled = true);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          strokeWidth: 8,
                        )
                      ),
                    )
                  );

                  signIn().then((value) {
                    setState(() => isLoginDisabled = false);
                    Navigator.of(context).pop();
                    context.go("/library");
                    // Navigator.pushNamed(context, "/library");
                  }).catchError((error) async {
                    setState(() => isLoginDisabled = false);
                    Navigator.of(context).pop();
                    return error;
                  });
                }
              },
              style: const ButtonStyle(
                minimumSize: MaterialStatePropertyAll<Size>(Size.fromHeight(50)),
                elevation: MaterialStatePropertyAll<double>(2.0),
              ),
              child: Row(
                children: const [
                  Spacer(),
                  Text("Continue"),
                  Spacer(),
                  Icon(Icons.arrow_right)
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const TitledDivider(title: "Or continue with"),
                  GoogleSignInButton(
                    title: "Sign in with Google",
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          context.go("/register");
                          // Navigator.pushReplacementNamed(
                          //   context,
                          //   "/register"
                          // );
                        },
                        child: const Text("Sign up")
                      )
                    ],
                  ),
                ],
              ),
            )
          ]
        )
      )
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}