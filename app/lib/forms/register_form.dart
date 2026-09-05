import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:papyrus/widgets/buttons/google_sign_in.dart';
import 'package:papyrus/widgets/input/email_input.dart';
import 'package:papyrus/widgets/input/name_input.dart';
import 'package:papyrus/widgets/input/password_input.dart';
import 'package:papyrus/widgets/titled_divider.dart';
import 'package:provider/provider.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterForm();
}

class _RegisterForm extends State<RegisterForm> {
  bool isRegisterDisabled = false;

  final formKey = GlobalKey<FormState>();
  final displayNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  Future<bool> signUp() async {
    return context.read<AuthProvider>().register(
      displayName: displayNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
    );
  }

  Future<void> _handleRegister() async {
    if (!formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => isRegisterDisabled = true);

    showDialog(
      animationStyle: AppMotion.animationStyle(context),
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: SizedBox(width: 150, height: 150, child: AppCircularProgressIndicator(strokeWidth: 8))),
    );

    try {
      final success = await signUp();
      if (!mounted) return;
      setState(() => isRegisterDisabled = false);
      Navigator.of(context).pop();

      if (success) {
        context.goNamed("LIBRARY");
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(context.read<AuthProvider>().error ?? "Account creation failed."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isRegisterDisabled = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: AppMotion.animationStyle(context),
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text("Account creation failed."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
              child: Text("Sign up", style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 16),
            NameInput(labelText: "Display name", controller: displayNameController),
            const SizedBox(height: 24),
            EmailInput(labelText: "Email address", controller: emailController),
            const SizedBox(height: 24),
            PasswordInput(labelText: "Password", controller: passwordController),
            const SizedBox(height: 24),
            PasswordInput(
              labelText: "Repeat password",
              controller: repeatPasswordController,
              extraValidator: (repeatedPassword) {
                if (passwordController.text != repeatedPassword) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isRegisterDisabled ? null : _handleRegister,
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll<Size>(Size.fromHeight(46)),
                elevation: WidgetStatePropertyAll<double>(2.0),
              ),
              child: const Row(children: [Spacer(), Text("Continue"), Spacer(), Icon(Icons.arrow_right)]),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const TitledDivider(title: "Or continue with"),
                  const GoogleSignInButton(title: "Sign up with Google"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(onPressed: () => context.go("/login"), child: const Text("Sign in")),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }
}
