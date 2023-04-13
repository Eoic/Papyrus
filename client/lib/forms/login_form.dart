import 'package:client/widgets/buttons/google_sign_in.dart';
import 'package:client/widgets/text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginForm extends StatelessWidget {
  LoginForm({ super.key });

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
              child: Text(
                  "Sign in",
                  style: TextStyle(
                    fontSize: 24
                  )
              ),
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 16),
            const TextInput(labelText: "Email address"),
            const SizedBox(height: 24),
            const TextInput(labelText: "Password"),
            Align(
              child: TextButton(
                onPressed: () {},
                child: Text("Forgot your password?"),
              ),
              alignment: Alignment.centerRight,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text("Continue"),
              style: ButtonStyle(
                minimumSize: MaterialStatePropertyAll<Size>(Size.fromHeight(46)),
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.blueAccent),
                foregroundColor: MaterialStatePropertyAll<Color>(Colors.white),
                shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)
                  )
                )
              )
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 0.0),
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
                  GoogleSignInButton(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(onPressed: () {}, child: Text("Sign up"))
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