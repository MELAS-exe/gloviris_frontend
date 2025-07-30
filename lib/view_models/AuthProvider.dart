// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/main_backend_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  String? _accessToken;
  String? _refreshToken;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // Check if user is authenticated on app start
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      // Check if we have stored tokens and validate them
      if (MainBackendService.isAuthenticated) {
        final profileResult = await MainBackendService.getUserProfile();
        
        if (profileResult['success'] == true) {
          _isAuthenticated = true;
          _user = profileResult['data'];
          _accessToken = MainBackendService.accessToken;
          _error = null;
        } else {
          _clearAuthData();
        }
      } else {
        _clearAuthData();
      }
    } catch (e) {
      _clearAuthData();
      _error = 'Failed to check authentication status: $e';
    }
    
    _setLoading(false);
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await MainBackendService.login(email, password);

      if (result['success'] == true) {
        _isAuthenticated = true;
        _user = result['user'];
        _accessToken = result['tokens']['access'];
        _refreshToken = result['tokens']['refresh'];
        _error = null;
        
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _error = result['error'] ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _setLoading(false);
      return false;
    }
  }

  // Register method
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await MainBackendService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      if (result['success'] == true) {
        _isAuthenticated = true;
        _user = result['user'];
        _accessToken = result['tokens']['access'];
        _refreshToken = result['tokens']['refresh'];
        _error = null;
        
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _error = result['error'] ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _setLoading(false);
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _setLoading(true);

    try {
      await MainBackendService.logout();
    } catch (e) {
      print('Logout error: $e');
    }

    _clearAuthData();
    _setLoading(false);
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      // Implement profile update in MainBackendService if needed
      // For now, just update local user data
      if (_user != null) {
        _user = {..._user!, ...profileData};
        notifyListeners();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _setLoading(false);
      return false;
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>?> getUserStatistics() async {
    if (!_isAuthenticated) return null;

    try {
      final result = await MainBackendService.getUserAnalysisStatistics();
      if (result['success'] == true) {
        return result['data'];
      }
      return null;
    } catch (e) {
      _error = 'Failed to get user statistics: $e';
      notifyListeners();
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearAuthData() {
    _isAuthenticated = false;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}