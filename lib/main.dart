import 'package:flutter/material.dart';
import 'package:gloviris_app/screens/LoginScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GlovIrisApp());
}

class GlovIrisApp extends StatelessWidget {
  const GlovIrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlovIris',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}