import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/sample_data.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/providers/sidebar_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:provider/provider.dart';

import 'config/app_router.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Papyrus());
}

class Papyrus extends StatelessWidget {
  const Papyrus({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core data store - single source of truth
        ChangeNotifierProvider(
          create: (_) => DataStore()
            ..loadData(
              books: SampleData.books,
              shelves: SampleData.shelves,
              tags: SampleData.tags,
              series: SampleData.seriesList,
              annotations: SampleData.annotations,
              notes: SampleData.notes,
              bookmarks: SampleData.bookmarks,
              readingSessions: SampleData.readingSessions,
              readingGoals: SampleData.readingGoals,
              bookShelfRelations: SampleData.bookShelfRelations,
              bookTagRelations: SampleData.bookTagRelations,
            ),
        ),
        // Auth and UI state providers
        ChangeNotifierProvider(create: (_) => GoogleSignInProvider()),
        ChangeNotifierProvider(create: (_) => DisplayModeProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: Consumer<DisplayModeProvider>(
        builder: (context, displayModeProvider, child) {
          return MaterialApp.router(
            title: 'Papyrus',
            debugShowCheckedModeBanner: false,
            // Theme configuration
            theme: displayModeProvider.isEinkMode
                ? AppTheme.eink
                : AppTheme.light,
            darkTheme: displayModeProvider.isEinkMode
                ? AppTheme.eink
                : AppTheme.dark,
            // Use system theme mode unless e-ink mode is active
            themeMode: displayModeProvider.isEinkMode
                ? ThemeMode.light
                : ThemeMode.system,
            routerConfig: AppRouter().router,
          );
        },
      ),
    );
  }
}
