// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';

class AppProvider with ChangeNotifier {
  int _currentTabIndex = 0;
  bool _isDarkMode = false;
  String _currentLanguage = 'fr';
  bool _isOfflineMode = false;
  bool _showOnboarding = true;
  Map<String, dynamic> _appSettings = {};

  // Getters
  int get currentTabIndex => _currentTabIndex;
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  bool get isOfflineMode => _isOfflineMode;
  bool get showOnboarding => _showOnboarding;
  Map<String, dynamic> get appSettings => _appSettings;

  // Tab navigation
  void setCurrentTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Theme management
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveSettings();
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
    _saveSettings();
  }

  // Language management
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
    _saveSettings();
  }

  // Offline mode
  void setOfflineMode(bool isOffline) {
    _isOfflineMode = isOffline;
    notifyListeners();
    _saveSettings();
  }

  // Onboarding
  void completeOnboarding() {
    _showOnboarding = false;
    notifyListeners();
    _saveSettings();
  }

  // App settings
  void updateSetting(String key, dynamic value) {
    _appSettings[key] = value;
    notifyListeners();
    _saveSettings();
  }

  void updateSettings(Map<String, dynamic> settings) {
    _appSettings.addAll(settings);
    notifyListeners();
    _saveSettings();
  }

  // Load settings from storage
  Future<void> loadSettings() async {
    try {
      // TODO: Implement actual storage loading
      // For now, using default values
      
      // Example of loading from SharedPreferences or other storage
      // final prefs = await SharedPreferences.getInstance();
      // _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      // _currentLanguage = prefs.getString('currentLanguage') ?? 'fr';
      // _isOfflineMode = prefs.getBool('isOfflineMode') ?? false;
      // _showOnboarding = prefs.getBool('showOnboarding') ?? true;
      
      notifyListeners();
    } catch (e) {
      print('Failed to load settings: $e');
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      // TODO: Implement actual storage saving
      
      // Example of saving to SharedPreferences
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('isDarkMode', _isDarkMode);
      // await prefs.setString('currentLanguage', _currentLanguage);
      // await prefs.setBool('isOfflineMode', _isOfflineMode);
      // await prefs.setBool('showOnboarding', _showOnboarding);
      
    } catch (e) {
      print('Failed to save settings: $e');
    }
  }

  // Network status
  void updateNetworkStatus(bool isConnected) {
    if (!isConnected && !_isOfflineMode) {
      _isOfflineMode = true;
      notifyListeners();
    } else if (isConnected && _isOfflineMode) {
      _isOfflineMode = false;
      notifyListeners();
    }
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];
  }

  // Get app statistics
  Map<String, dynamic> getAppStatistics() {
    return {
      'language': _currentLanguage,
      'darkMode': _isDarkMode,
      'offlineMode': _isOfflineMode,
      'currentTab': _currentTabIndex,
      'onboardingCompleted': !_showOnboarding,
    };
  }

  // Reset app to defaults
  void resetToDefaults() {
    _currentTabIndex = 0;
    _isDarkMode = false;
    _currentLanguage = 'fr';
    _isOfflineMode = false;
    _showOnboarding = true;
    _appSettings.clear();
    
    notifyListeners();
    _saveSettings();
  }
}