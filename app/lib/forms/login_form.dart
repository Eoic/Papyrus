import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/widgets/buttons/google_sign_in.dart';
import 'package:papyrus/widgets/input/email_input.dart';
import 'package:papyrus/widgets/input/password_input.dart';
import 'package:papyrus/widgets/titled_divider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginForm();
}

class _LoginForm extends State<LoginForm> {
  bool isLoginDisabled = false;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(
    text: "karolis.strazdas.sso@gmail.com",
  );
  final passwordController = TextEditingController(text: "");

  Future<AuthResponse> signIn() async {
    return Supabase.instance.client.auth.signInWithPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  Future<void> _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => isLoginDisabled = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(strokeWidth: 8),
        ),
      ),
    );

    try {
      await signIn();
      if (!mounted) return;
      setState(() => isLoginDisabled = false);
      Navigator.of(context).pop();
      context.goNamed('LIBRARY');
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoginDisabled = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text("Incorrect username or password."),
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
        padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sign in",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),
            EmailInput(labelText: "Email address", controller: emailController),
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
              onPressed: isLoginDisabled ? null : _handleLogin,
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll<Size>(Size.fromHeight(50)),
                elevation: WidgetStatePropertyAll<double>(2.0),
              ),
              child: const Row(
                children: [
                  Spacer(),
                  Text("Continue"),
                  Spacer(),
                  Icon(Icons.arrow_right),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const TitledDivider(title: "Or continue with"),
                  const GoogleSignInButton(title: "Sign in with Google"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => context.go("/register"),
                        child: const Text("Sign up"),
                      ),
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
