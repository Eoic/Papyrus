import 'package:client/widgets/titled_divider.dart';
import 'package:flutter/material.dart';
import 'package:client/types/input_type.dart';
import 'package:client/widgets/text_input.dart';
import 'package:client/widgets/buttons/google_sign_in.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({ super.key });

  @override
  Widget build(BuildContext context) {
    return Form(
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
            TextInput(labelText: "Email address", type: InputType.email,),
            const SizedBox(height: 24),
            TextInput(labelText: "Password", type: InputType.password),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("Forgot your password?"),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
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