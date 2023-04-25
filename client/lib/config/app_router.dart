
import 'package:client/pages/book_details_page.dart';
import 'package:client/pages/dashboard_page.dart';
import 'package:client/pages/goals_page.dart';
import 'package:client/pages/library_page.dart';
import 'package:client/pages/login_page.dart';
import 'package:client/pages/profile_page.dart';
import 'package:client/pages/register_page.dart';
import 'package:client/pages/statistics_page.dart';
import 'package:client/pages/welcome_page.dart';
import 'package:client/widgets/navbar_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// https://github.com/bizz84/nested_navigation_examples/blob/d0b5dc691c4620cd54fe6864aed01b76dbf77091/examples/gorouter/lib/main.dart#L94

class AppRouter {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  final tabs = [
    ScaffoldWithNavBarTabItem(
      initialLocation: '/dashboard',
      icon: const Icon(Icons.dashboard),
      label: "Dashboard"
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/library',
      icon: const Icon(Icons.library_books),
      label: "Library",
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/goals',
      icon: const Icon(Icons.emoji_events),
      label: "Goals"
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/statistics',
      icon: const Icon(Icons.stacked_line_chart),
      label: "Statistics"
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/profile',
      icon: const Icon(Icons.person),
      label: "Profile"
    )
  ];

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
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
            },
          ),
          GoRoute(
            path: "register",
            builder: (BuildContext context, GoRouterState state) {
              return RegisterPage();
            }
          )
        ],
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(
            tabs: tabs,
            child: child
          );
        },
        routes: [
          GoRoute(
            path: "/dashboard",
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardPage()
            ),
          ),
          GoRoute(
            path: "/library",
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: LibraryPage()
            ),
            routes: [
              GoRoute(
                name: 'BOOK_DETAILS',
                path: 'details/:bookId',
                builder: (context, state) {
                  var bookId = state.params["bookId"];
                  return BookDetailsPage(id: bookId);
                }
              )
            ]
          ),
          GoRoute(
            path: "/goals",
            pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const GoalsPage()
            )
          ),
          GoRoute(
            path: "/statistics",
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StatisticsPage()
            )
          ),
          GoRoute(
            path: "/profile",
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfilePage()
            )
          )
        ]
      )
    ],
    redirect: (BuildContext context, GoRouterState state) {
      if (FirebaseAuth.instance.currentUser == null) {
        if (state.subloc.contains("/login") || state.subloc.contains("/register")) {
          return null;
        }

        return "/";
      }

      if (state.subloc == "/") {
        return "/profile";
      }

      return null;
    },
  );
}