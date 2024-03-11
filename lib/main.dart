import 'dart:io';

import 'package:ai_calendar_app/notificationController.dart';
import 'package:ai_calendar_app/providers/aiFunctions.dart';

import 'package:ai_calendar_app/firebase_options.dart';
import 'package:ai_calendar_app/providers/journalProvider.dart';
import 'package:ai_calendar_app/providers/stateProvider.dart';
import 'package:ai_calendar_app/views/home.dart';
import 'package:ai_calendar_app/views/splash.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ai_calendar_app/providers/auth.dart' as auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // name: Platform.operatingSystem == "ios" ? "AI-Calendar" : null,
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AIFunctions("", "", "")),
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoadingState()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
      ],
      child: MaterialApp(
        title: 'AI Calendar',
        debugShowCheckedModeBanner: false,
        theme: FlexThemeData.dark(
          scheme: FlexScheme.blue,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 7,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 10,
            blendOnColors: false,
            useTextTheme: true,
            useM2StyleDividerInM3: true,
            alignedDropdown: true,
            useInputDecoratorThemeInDialogs: true,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          textTheme: GoogleFonts.leagueSpartanTextTheme(),
        ),
        darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.blue,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 7,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 10,
            blendOnColors: false,
            useTextTheme: true,
            useM2StyleDividerInM3: true,
            alignedDropdown: true,
            useInputDecoratorThemeInDialogs: true,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          textTheme: GoogleFonts.leagueSpartanTextTheme(),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
