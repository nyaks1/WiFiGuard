import 'package:flutter/material.dart';
import 'package:wifiguard/screens/scan_screen.dart';

class WiFiGuardApp extends StatelessWidget {
  const WiFiGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navyPrimary = Color(0xFF0F172A); // Slate 900
    const goldPrimary = Color(0xFFD4AF37); // Gold

    return MaterialApp(
      title: 'WiFiGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: goldPrimary,
        scaffoldBackgroundColor: navyPrimary,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: goldPrimary,
          secondary: goldPrimary,
          background: navyPrimary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
      home: const ScanScreen(),
    );
  }
}
