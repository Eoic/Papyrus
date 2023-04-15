import 'package:client/pages/library_page.dart';
import 'package:client/pages/splash_screen_page.dart';
import 'package:client/providers/google_sign_in_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:client/pages/welcome_page.dart';
import 'package:provider/provider.dart';

import 'pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:client/themes/color_schemes.g.dart';
import 'package:client/pages/register_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Papyrus());
}

class Papyrus extends StatelessWidget {
  const Papyrus({ super.key });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GoogleSignInProvider(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        // theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        initialRoute: "/",
        routes: {
          "/": (context) => const SplashScreenPage(),
          "/login": (context) => LoginPage(),
          "/welcome": (context) => const WelcomePage(),
          "/register": (context) => RegisterPage(),
          "/library": (context) => const LibraryPage(),
        },
      ),
    );
  }
}