import 'package:client/pages/book_details_page.dart';
import 'package:client/pages/dashboard_page.dart';
import 'package:client/pages/goals_page.dart';
import 'package:client/pages/login_page.dart';
import 'package:client/pages/profile_page.dart';
import 'package:client/pages/register_page.dart';
import 'package:client/pages/statistics_page.dart';
import 'package:client/pages/stub_page.dart';
import 'package:client/pages/welcome_page.dart';
import 'package:client/widgets/navbar_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../pages/search_options_page.dart';
import '../widgets/drawer_scaffold.dart';

class AppRouter {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();
  final drawerShellNavigatorKey = GlobalKey<NavigatorState>();

  final bottomGlobalNavigationTabs = [
    ScaffoldWithNavBarTabItem(
      initialLocation: '/dashboard',
      icon: const Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/library',
      icon: const Icon(Icons.library_books),
      label: 'Library',
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/goals',
      icon: const Icon(Icons.emoji_events),
      label: 'Goals',
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/statistics',
      icon: const Icon(Icons.stacked_line_chart),
      label: 'Statistics',
    ),
    ScaffoldWithNavBarTabItem(
      initialLocation: '/profile',
      icon: const Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  final libraryDrawerTabs = [
    const ScaffoldWithDrawerTabItem(
      initialLocation: '/library/books',
      label: 'All books',
      icon: Icon(Icons.stacked_bar_chart),
    ),
    const ScaffoldWithDrawerTabItem(
      initialLocation: '/library/shelves',
      label: 'Shelves',
      icon: Icon(Icons.shelves),
    ),
    const ScaffoldWithDrawerTabItem(
      initialLocation: '/library/topics',
      label: 'Topics',
      icon: Icon(Icons.topic),
    ),
    const ScaffoldWithDrawerTabItem(
      initialLocation: '/library/bookmarks',
      label: 'Bookmarks',
      icon: Icon(Icons.bookmark),
    ),
    const ScaffoldWithDrawerTabItem(
      initialLocation: '/library/annotations',
      label: 'Annotations',
      icon: Icon(Icons.border_color),
    ),
    const ScaffoldWithDrawerTabItem(
      initialLocation: '/library/notes',
      label: 'Notes',
      icon: Icon(Icons.notes),
    ),
  ];

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomePage();
        },
        routes: [
          GoRoute(
            name: 'LOGIN',
            path: 'login',
            builder: (BuildContext context, GoRouterState state) {
              return const LoginPage();
            },
          ),
          GoRoute(
            name: 'REGISTER',
            path: 'register',
            builder: (BuildContext context, GoRouterState state) {
              return const RegisterPage();
            },
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(
            tabs: bottomGlobalNavigationTabs,
            child: child,
          );
        },
        routes: [
          GoRoute(
            name: 'DASHBOARD',
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
            ),
          ),
          ShellRoute(
            navigatorKey: drawerShellNavigatorKey,
            pageBuilder: (context, state, widget) {
              return NoTransitionPage(
                key: state.pageKey,
                child: ScaffoldWithDrawer(
                  tabs: libraryDrawerTabs,
                  child: widget,
                ),
              );
            },
            routes: [
              GoRoute(
                name: 'LIBRARY',
                path: '/library',
                redirect: (context, state) {
                  return state.uri.toString() == '/library'
                      ? '/library/books'
                      : null;
                },
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const StubPage(title: 'Loading...'),
                ),
                routes: [
                  GoRoute(
                    name: 'BOOKS',
                    path: 'books',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const StubPage(title: 'Books'),
                    ),
                  ),
                  GoRoute(
                    name: 'SHELVES',
                    path: 'shelves',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const StubPage(title: 'Shelves'),
                    ),
                  ),
                  GoRoute(
                    name: 'TOPICS',
                    path: 'topics',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const StubPage(title: 'Topics'),
                    ),
                  ),
                  GoRoute(
                    name: 'SEARCH_OPTIONS',
                    path: 'search/options',
                    builder: (context, state) {
                      return const SearchOptionsPage();
                    },
                  ),
                  GoRoute(
                    name: 'BOOK_DETAILS',
                    path: 'details/:bookId',
                    builder: (context, state) {
                      var bookId = state.pathParameters['bookId'];
                      return BookDetailsPage(id: bookId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            name: 'GOALS',
            path: '/goals',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const GoalsPage()),
          ),
          GoRoute(
            name: 'STATISTICS',
            path: '/statistics',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StatisticsPage(),
            ),
          ),
          GoRoute(
            name: 'PROFILE',
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      if (FirebaseAuth.instance.currentUser == null) {
        if (state.uri.toString().contains('/login') ||
            state.uri.toString().contains('/register')) {
          return null;
        }

        return '/';
      }

      if (state.uri.toString() == '/') {
        return '/library/books';
      }

      return null;
    },
  );
}
