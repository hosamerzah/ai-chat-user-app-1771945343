import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_chat_app/l10n/app_localizations.dart';
import 'package:ai_chat_app/themes/light_theme.dart';
import 'package:ai_chat_app/themes/dark_theme.dart';
import 'package:ai_chat_app/screens/login_screen.dart';
import 'package:ai_chat_app/screens/home_screen.dart';
import 'package:ai_chat_app/screens/admin_screen.dart';
import 'package:ai_chat_app/screens/reviewer_screen.dart';
import 'package:ai_chat_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:ai_chat_app/providers/theme_provider.dart';
import 'package:ai_chat_app/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize FirebaseService if needed.
  // Ensure any other asynchronous initialization happens before running the app.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'AI Chat App',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', ''), // Arabic
              Locale('en', ''), // English
            ],
            locale: localeProvider.locale,
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            home: StreamBuilder(
              stream: FirebaseService().authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  // User is not logged in
                  if (snapshot.data == null) {
                    return const LoginScreen();
                  }
                  final user = snapshot.data;
                  final uid = user?.uid;
                  if (uid == null) {
                    return const HomeScreen();
                  }
                  // Use a FutureBuilder to fetch the user's role and route accordingly
                  return FutureBuilder<Map<String, dynamic>?> (
                    future: FirebaseService().getUser(uid),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final userData = userSnapshot.data;
                      final role = userData?['role'] ?? 'user';
                      if (role == 'admin') {
                        // If the user is an admin, navigate to AdminScreen
                        return const AdminScreen();
                      } else if (role == 'reviewer') {
                        // If the user is a reviewer, navigate to ReviewerScreen
                        return const ReviewerScreen();
                      } else {
                        return const HomeScreen();
                      }
                    },
                  );
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
