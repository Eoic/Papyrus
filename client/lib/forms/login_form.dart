import 'package:client/pages/login_page.dart';
import 'package:client/pages/register_page.dart';
import 'package:client/types/input_type.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/text_input.dart';
import 'package:client/widgets/buttons/google_sign_in.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({ super.key });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  "Sign in",
                  style: TextStyle(
                      fontSize: 24
                  )
              ),
            ),
            const SizedBox(height: 16),
            const TextInput(labelText: "Email address", type: InputType.email,),
            const SizedBox(height: 24),
            const TextInput(labelText: "Password", type: InputType.password),
            Align(
              child: TextButton(
                onPressed: () {},
                child: Text("Forgot your password?"),
              ),
              alignment: Alignment.centerRight,
            ),
            ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(46)),
                backgroundColor: const MaterialStatePropertyAll<Color>(Colors.blueAccent),
                foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
                shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)
                  )
                )
              ),
              child: const Text("Continue"),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 0.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1.5,
                            color: Colors.grey[400]
                          )
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                              "Or continue with",
                              style: TextStyle(color: Colors.grey[700])
                          )
                        ),
                        Expanded(
                          child: Divider(
                              thickness: 1.5,
                              color: Colors.grey[400]
                          )
                        )
                      ],
                    ),
                  ),
                  GoogleSignInButton(
                    title: "Sign in with Google",
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            "/register"
                          );
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
}