import 'package:client/pages/welcome_page.dart';

import 'pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:client/themes/color_schemes.g.dart';
import 'package:client/pages/register_page.dart';

void main() {
  runApp(const Papyrus());
}

class Papyrus extends StatelessWidget {
  const Papyrus({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      // theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      initialRoute: "/welcome",
      routes: {
        "/": (context) => const LoginPage(),
        "/welcome": (context) => const WelcomePage(),
        "/register": (context) => const RegisterPage(),
      },
    );
  }
}