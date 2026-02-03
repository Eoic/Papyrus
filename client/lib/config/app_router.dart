import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/pages/book_details_page.dart';
import 'package:papyrus/pages/book_edit_page.dart';
import 'package:papyrus/pages/dashboard_page.dart';
import 'package:papyrus/pages/developer_options_page.dart';
import 'package:papyrus/pages/goals_page.dart';
import 'package:papyrus/pages/library_page.dart';
import 'package:papyrus/pages/login_page.dart';
import 'package:papyrus/pages/profile_page.dart';
import 'package:papyrus/pages/register_page.dart';
import 'package:papyrus/pages/search_options_page.dart';
import 'package:papyrus/pages/settings_page.dart';
import 'package:papyrus/pages/shelves_page.dart';
import 'package:papyrus/pages/statistics_page.dart';
import 'package:papyrus/pages/stub_page.dart';
import 'package:papyrus/pages/welcome_page.dart';
import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';

class AppRouter {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    routes: [
      // Auth routes (no shell)
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
      // Main app routes (with adaptive shell)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AdaptiveAppShell(child: child);
        },
        routes: [
          // Dashboard
          GoRoute(
            name: 'DASHBOARD',
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
            ),
          ),
          // Library and sub-routes
          GoRoute(
            name: 'LIBRARY',
            path: '/library',
            redirect: (context, state) {
              // Redirect /library to /library/books
              return state.uri.toString() == '/library'
                  ? '/library/books'
                  : null;
            },
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LibraryPage(),
            ),
            routes: [
              GoRoute(
                name: 'BOOKS',
                path: 'books',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const LibraryPage(),
                ),
              ),
              GoRoute(
                name: 'SHELVES',
                path: 'shelves',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ShelvesPage(),
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
                name: 'BOOKMARKS',
                path: 'bookmarks',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const StubPage(title: 'Bookmarks'),
                ),
              ),
              GoRoute(
                name: 'ANNOTATIONS',
                path: 'annotations',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const StubPage(title: 'Annotations'),
                ),
              ),
              GoRoute(
                name: 'NOTES',
                path: 'notes',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const StubPage(title: 'Notes'),
                ),
              ),
              GoRoute(
                name: 'SEARCH_OPTIONS',
                path: 'search/options',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SearchOptionsPage(),
                ),
              ),
              GoRoute(
                name: 'BOOK_DETAILS',
                path: 'details/:bookId',
                pageBuilder: (context, state) {
                  var bookId = state.pathParameters['bookId'];
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: BookDetailsPage(id: bookId),
                  );
                },
              ),
              GoRoute(
                name: 'BOOK_EDIT',
                path: 'edit/:bookId',
                pageBuilder: (context, state) {
                  var bookId = state.pathParameters['bookId'];
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: BookEditPage(id: bookId),
                  );
                },
              ),
            ],
          ),
          // Goals
          GoRoute(
            name: 'GOALS',
            path: '/goals',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const GoalsPage()),
          ),
          // Statistics
          GoRoute(
            name: 'STATISTICS',
            path: '/statistics',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StatisticsPage(),
            ),
          ),
          // Profile
          GoRoute(
            name: 'PROFILE',
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
          ),
          // Settings
          GoRoute(
            name: 'SETTINGS',
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
          ),
          // Developer Options (debug only)
          if (kDebugMode)
            GoRoute(
              name: 'DEVELOPER_OPTIONS',
              path: '/developer-options',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DeveloperOptionsPage(),
              ),
            ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // TODO: Remove this flag before production - bypasses authentication
      const bypassAuth = true;

      if (bypassAuth) {
        // When bypassing auth, only redirect root to library
        if (state.uri.toString() == '/') {
          return '/library/books';
        }
        return null;
      }

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
