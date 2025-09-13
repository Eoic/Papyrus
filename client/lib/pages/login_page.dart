import 'package:flutter/material.dart';
import 'package:papyrus/forms/login_form.dart';
import 'package:papyrus/widgets/heading.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Heading(subtitle: "All your books in one place"),
                    Expanded(child: LoginForm()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
