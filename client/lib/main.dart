import 'package:client/providers/google_sign_in_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/app_router.dart';
import 'package:flutter/material.dart';
import 'package:client/themes/color_schemes.g.dart';

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
      child: MaterialApp.router(
        // theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        routerConfig: AppRouter().router,
      ),
    );
  }
}