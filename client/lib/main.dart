import 'package:client/pages/register_page.dart';

import 'pages/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Papyrus());
}

class Papyrus extends StatelessWidget {
  const Papyrus({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      initialRoute: "/",
      routes: {
        "/": (context) => const LoginPage(),
        "/register": (context) => const RegisterPage(),
      },
    );
  }
}