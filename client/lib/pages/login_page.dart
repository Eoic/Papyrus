import 'package:client/forms/login_form.dart';
import 'package:client/widgets/heading.dart';
import 'package:flutter/material.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Container(
                child: Heading(subtitle: "All your books in one place",),
                padding: EdgeInsets.all(24.0),
              ),
              Expanded(child: LoginForm())
            ]
          ),
        )
      ),
    );
  }
}