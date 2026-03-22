import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/screensaver_screen.dart';
import 'screens/afisha_screen.dart';
import 'screens/kruzhki_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/admin_panel.dart';
import 'utils/constants.dart';

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'КДЦ Тимоново',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const HomeScreen();
            break;
          case '/admin':
            page = const AdminPanel();
            break;
          case '/afisha':
            page = const AfishaScreen();
            break;
          case '/kruzhki':
            page = const KruzhkiScreen();
            break;
          case '/gallery':
            page = const GalleryScreen();
            break;
          case '/contacts':
            page = const ContactsScreen();
            break;
          case '/screensaver':
            page = const ScreensaverScreen();
            break;
          default:
            page = const HomeScreen();
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppDurations.fadeTransition,
        );
      },
    );
  }
}
