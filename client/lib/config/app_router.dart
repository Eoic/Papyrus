import 'package:client/pages/library_page.dart';
import 'package:client/pages/login_page.dart';
import 'package:client/pages/register_page.dart';
import 'package:client/pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
          path: "/",
          builder: (BuildContext context, GoRouterState state) {
            return const WelcomePage();
          },
          routes: [
            GoRoute(
                path: "login",
                builder: (BuildContext context, GoRouterState state) {
                  return LoginPage();
                }
            ),
            GoRoute(
                path: "register",
                builder: (BuildContext context, GoRouterState state) {
                  return RegisterPage();
                }
            )
          ]
      ),
      GoRoute(
        path: "/library",
        builder: (BuildContext context, GoRouterState state) {
          return const LibraryPage();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      if (FirebaseAuth.instance.currentUser == null) {
        if (state.subloc.contains("login") || state.subloc.contains("register")) {
          return null;
        }

        return "/";
      }

      return "/library";
    },
  );
}