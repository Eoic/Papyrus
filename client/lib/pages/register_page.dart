import 'package:flutter/material.dart';
import 'package:papyrus/forms/register_form.dart';
import 'package:papyrus/widgets/heading.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
                    Expanded(child: RegisterForm()),
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
