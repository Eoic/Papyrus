import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/data/sample_data.dart';
import 'package:papyrus/providers/community_provider.dart';
import 'package:papyrus/providers/display_mode_provider.dart';
import 'package:papyrus/providers/google_sign_in_provider.dart';
import 'package:papyrus/providers/library_provider.dart';
import 'package:papyrus/providers/social_provider.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sidebar_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_router.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  runApp(Papyrus(prefs: prefs));
}

class Papyrus extends StatefulWidget {
  final SharedPreferences prefs;

  const Papyrus({super.key, required this.prefs});

  @override
  State<Papyrus> createState() => _PapyrusState();
}

class _PapyrusState extends State<Papyrus> {
  late final AppRouter _appRouter = AppRouter();

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
        ChangeNotifierProvider(
          create: (_) => PreferencesProvider(widget.prefs),
        ),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
      ],
      child: Consumer2<DisplayModeProvider, PreferencesProvider>(
        builder: (context, displayModeProvider, preferencesProvider, child) {
          return MaterialApp.router(
            title: 'Papyrus',
            debugShowCheckedModeBanner: false,
            theme: displayModeProvider.isEinkMode
                ? AppTheme.eink
                : AppTheme.light,
            darkTheme: displayModeProvider.isEinkMode
                ? AppTheme.eink
                : AppTheme.dark,
            themeMode: displayModeProvider.isEinkMode
                ? ThemeMode.light
                : preferencesProvider.themeMode,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
