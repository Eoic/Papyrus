import 'package:client/widgets/input/email_input.dart';
import 'package:client/widgets/input/password_input.dart';
import 'package:client/widgets/titled_divider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/buttons/google_sign_in.dart';
import 'package:go_router/go_router.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({ super.key });

  @override
  State<RegisterForm> createState() => _RegisterForm();
}

class _RegisterForm extends State<RegisterForm> {
  bool isRegisterDisabled = false;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  Future<UserCredential> signUp() async {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text
    ).then((UserCredential user) {
      return user;
    }).catchError((error) async {
      var errorMessage = "Account creation failed.";

      if (error.code == "email-already-in-use") {
        errorMessage = "Account with this email already exists.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(errorMessage),
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
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 26.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sign up",
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
            const SizedBox(height: 24),
            PasswordInput(
              labelText: "Repeat password",
              controller: repeatPasswordController,
              extraValidator: (repeatedPassword) {
                if (passwordController.text != repeatedPassword) {
                  return "Passwords do not match";
                }
              },
            ),
            const SizedBox(height: 24,),
            ElevatedButton(
              onPressed: isRegisterDisabled ? null : () {
                if (formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  setState(() => isRegisterDisabled = true);

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

                  signUp().then((value) {
                    setState(() => isRegisterDisabled = false);
                    Navigator.of(context).pop();
                    context.goNamed("LIBRARY");
                  }).catchError((error) async {
                    setState(() => isRegisterDisabled = false);
                    Navigator.of(context).pop();
                  });
                }
              },
              style: const ButtonStyle(
                minimumSize: MaterialStatePropertyAll<Size>(Size.fromHeight(46)),
                elevation: MaterialStatePropertyAll<double>(2.0),
              ),
              child: const Row(
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
                  const TitledDivider(
                    title: "Or continue with"
                  ),
                  const GoogleSignInButton(
                    title: "Sign up with Google",
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => context.go("/login"),
                        child: const Text("Sign in")
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
}