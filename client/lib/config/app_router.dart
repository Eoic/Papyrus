import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/pages/book_details_page.dart';
import 'package:papyrus/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:papyrus/pages/bookmarks_page.dart';
import 'package:papyrus/pages/book_edit_page.dart';
import 'package:papyrus/pages/dashboard_page.dart';
import 'package:papyrus/pages/developer_options_page.dart';
import 'package:papyrus/pages/goals_page.dart';
import 'package:papyrus/pages/library_page.dart';
import 'package:papyrus/pages/forgot_password_page.dart';
import 'package:papyrus/pages/login_page.dart';
import 'package:papyrus/pages/edit_profile_page.dart';
import 'package:papyrus/pages/profile_page.dart';
import 'package:papyrus/pages/register_page.dart';
import 'package:papyrus/pages/search_options_page.dart';
import 'package:papyrus/pages/shelf_contents_page.dart';
import 'package:papyrus/pages/shelves_page.dart';
import 'package:papyrus/pages/statistics_page.dart';
import 'package:papyrus/pages/annotations_page.dart';
import 'package:papyrus/pages/notes_page.dart';
import 'package:papyrus/pages/welcome_page.dart';
import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';

class AppRouter {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

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
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const LoginPage()),
          ),
          GoRoute(
            name: 'REGISTER',
            path: 'register',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const RegisterPage(),
            ),
          ),
          GoRoute(
            name: 'FORGOT_PASSWORD',
            path: 'forgot-password',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ForgotPasswordPage(),
            ),
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
                routes: [
                  GoRoute(
                    name: 'SHELF_CONTENTS',
                    path: ':shelfId',
                    pageBuilder: (context, state) {
                      final shelfId = state.pathParameters['shelfId'];
                      return NoTransitionPage(
                        key: state.pageKey,
                        child: ShelfContentsPage(shelfId: shelfId),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                name: 'BOOKMARKS',
                path: 'bookmarks',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const BookmarksPage(),
                ),
              ),
              GoRoute(
                name: 'ANNOTATIONS',
                path: 'annotations',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AnnotationsPage(),
                ),
              ),
              GoRoute(
                name: 'NOTES',
                path: 'notes',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const NotesPage(),
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
            routes: [
              GoRoute(
                name: 'EDIT_PROFILE',
                path: 'edit',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const EditProfilePage(),
                ),
              ),
            ],
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
      final isOffline = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).isOfflineMode;

      if (Supabase.instance.client.auth.currentSession == null && !isOffline) {
        if (state.uri.toString().contains('/login') ||
            state.uri.toString().contains('/register') ||
            state.uri.toString().contains('/forgot-password')) {
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
