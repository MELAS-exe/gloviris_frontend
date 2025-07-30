// lib/main.dart
import 'package:flutter/material.dart';
import 'package:gloviris_app/view_models/AppProvider.dart';
import 'package:gloviris_app/view_models/AuthProvider.dart';
import 'package:gloviris_app/view_models/PlantAnalysisProvider.dart';
import 'package:gloviris_app/view_models/SoilProvider.dart';
import 'package:provider/provider.dart';
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
    return MultiProvider(
      providers: [
        // App state provider
        ChangeNotifierProvider(create: (_) => AppProvider()),

        // Authentication provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Plant analysis provider
        ChangeNotifierProvider(create: (_) => PlantAnalysisProvider()),

        // Soil analysis provider
        ChangeNotifierProvider(create: (_) => SoilProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'GlovIris',
            theme: appProvider.isDarkMode ? _buildDarkTheme() : AppTheme.lightTheme,
            home: const AppInitializer(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryGreen,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.jostTextTheme(ThemeData.dark().textTheme),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Load app settings
    await appProvider.loadSettings();

    // Check authentication status
    await authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (authProvider.isLoading) {
          return const LoadingScreen();
        }

        // Navigate based on authentication status
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              child: Image.asset("assets/images/logo.png"),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppTheme.primaryYellow,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Initialisation de GlovIris...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}