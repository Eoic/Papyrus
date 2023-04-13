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
      home: const LoginPage(),
      theme: ThemeData.light(useMaterial3: true)
    );
  }
}