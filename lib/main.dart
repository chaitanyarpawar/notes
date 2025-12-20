import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/checklist_provider.dart';
// import 'providers/speech_provider.dart';
import 'services/hive_service.dart';
import 'services/ad_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
// import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize services
    await HiveService.init();
    // Checklist now uses SharedPreferences-based storage; no heavy database init
    await AdMobService.initialize();
    // Initialize local notifications (channels, permissions where applicable)
    await NotificationService.initialize();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    // Log initialization error (print removed for production)
    // Continue running the app even if some services fail to initialize
  }

  // Disable debug banner in debug mode
  if (kDebugMode) {
    WidgetsApp.debugAllowBannerOverride = false;
  }

  runApp(const PebbleNoteApp());
}

class PebbleNoteApp extends StatelessWidget {
  const PebbleNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        // Speech-to-text removed; no SpeechProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'PebbleNote',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.buildLightTheme(),
            darkTheme: themeProvider.buildDarkTheme(),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  navigatorKey: NavigationService.navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Explicit "new" routes BEFORE parameter routes
    GoRoute(
      path: '/note/new',
      name: 'note-new',
      builder: (context, state) {
        final isChecklist = state.uri.queryParameters['isChecklist'] == 'true';
        final category = state.uri.queryParameters['category'] ?? 'Personal';
        debugPrint(
            '🎯 Router: Building NoteEditor (NEW) category: $category url: ${state.uri}');
        return NoteEditorScreen(
          isChecklist: isChecklist,
          category: category,
        );
      },
    ),
    GoRoute(
      path: '/note/:id',
      name: 'note-edit',
      builder: (context, state) {
        final noteId = state.pathParameters['id'];
        return NoteEditorScreen(noteId: noteId);
      },
    ),
    GoRoute(
      path: '/checklist/new',
      name: 'checklist-new',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'Personal';
        debugPrint(
            '🎯 Router: Building ChecklistScreen (NEW) category: $category url: ${state.uri}');
        return ChecklistScreen(category: category);
      },
    ),
    GoRoute(
      path: '/checklist/:id',
      name: 'checklist-edit',
      builder: (context, state) {
        final noteId = state.pathParameters['id'];
        return ChecklistScreen(noteId: noteId);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
  ],
);
