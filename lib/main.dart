// [FLOW STEP 1] main.dart - Entry Point: Where the app initializes Firebase & loads state Providers
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'package:moodwalls/firebase_options.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_provider.dart';
import 'package:moodwalls/features/home/1_splash_screen.dart';
import 'package:moodwalls/features/auth/3_login_screen.dart';
import 'package:moodwalls/features/auth/5_signup_screen.dart';
import 'package:moodwalls/features/home/6_home_screen.dart';
import 'package:moodwalls/features/auth/2_role_selection_screen.dart';
import 'package:moodwalls/features/auth/4_admin_login_screen.dart';
import 'package:moodwalls/features/wallpaper/7_gallery_screen.dart';
import 'package:moodwalls/features/wallpaper/my_mood_wallpapers_screen.dart';
import 'package:moodwalls/features/admin/9_admin_dashboard.dart';
import 'package:moodwalls/features/profile/profile_screen.dart';
import 'package:moodwalls/features/mood/mood_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    // handle web specific errors gracefully
    if (details.exception.toString().contains('doHttp') || 
        details.exception.toString().contains('unsupported operation')) {
      debugPrint('Web platform HTTP error detected - this is expected on web platform');
    }
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MoodWallsApp());
}

class MoodWallsApp extends StatelessWidget {
  const MoodWallsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WallpaperProvider()),
        ChangeNotifierProvider(create: (_) => MoodThemeProvider()),
      ],
      child: MaterialApp(
        title: 'MoodWalls',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/mood-history': (context) => const MoodHistoryScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/admin-login': (context) => const AdminLoginScreen(),
        },
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/gallery') {
            final mood = settings.arguments is String && (settings.arguments as String).isNotEmpty
                ? settings.arguments as String
                : 'Happy';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => GalleryScreen(mood: mood),
            );
          }
          if (settings.name == '/my-wallpapers') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MyMoodWallpapersScreen(),
            );
          }
          return null;
        },
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'An error occurred',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        details.exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          };
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          );
        },
      ),
    );
  }
}
