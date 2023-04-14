import 'package:client/forms/login_form.dart';
import 'package:client/widgets/heading.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: const [
                    Heading(subtitle: "All your books in one place",),
                    Expanded(child: LoginForm())
                  ]
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}