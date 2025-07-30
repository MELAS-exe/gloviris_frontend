// lib/services/main_backend_service.dart
// Enhanced version with analysis history integration

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_analysis_result.dart';

class MainBackendService {
  // Main Django backend (spacehack2) - update with your actual IP
  static const String mainBaseUrl = 'http://172.16.16.198:8000'; // Update this
  // Plant AI backend - update with your actual IP
  static const String plantAiBaseUrl = 'http://172.16.16.198:8001'; // Different port

  static String? _accessToken;
  static String? _refreshToken;

  // Authentication methods (same as before)
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$mainBaseUrl/users/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];

        return {
          'success': true,
          'user': data['user'],
          'tokens': data['tokens'],
        };
      } else {
        return {
          'success': false,
          'error': 'Login failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$mainBaseUrl/users/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];

        return {
          'success': true,
          'user': data['user'],
          'tokens': data['tokens'],
        };
      } else {
        return {
          'success': false,
          'error': 'Registration failed: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // ENHANCED: Plant AI Analysis with automatic saving to database
  static Future<Map<String, dynamic>> analyzePlantWithDatabase(String imagePath) async {
    try {
      print('Starting enhanced plant analysis for: $imagePath');

      // Step 1: Get AI analysis from plant AI backend
      final aiResult = await _getPlantAiAnalysis(imagePath);
      print('AI Analysis result: $aiResult');

      if (!aiResult['success']) {
        return aiResult;
      }

      // Ensure we have proper data structure
      Map<String, dynamic> aiData;
      if (aiResult['data'] is Map<String, dynamic>) {
        aiData = aiResult['data'];
      } else if (aiResult['data'] is Map) {
        aiData = Map<String, dynamic>.from(aiResult['data']);
      } else {
        return {
          'success': false,
          'error': 'Invalid AI response format',
        };
      }

      // Step 2: Try to match with database plants
      Map<String, dynamic>? matchedPlant;
      try {
        matchedPlant = await _findMatchingPlant(aiData['espece']?.toString() ?? '');
      } catch (e) {
        print('Error finding matching plant: $e');
        matchedPlant = null;
      }

      // Step 3: Get compatible soils if plant matched
      List<Map<String, dynamic>>? compatibleSoils;
      if (matchedPlant != null) {
        try {
          final soilResponse = await _getSoilsForPlant(matchedPlant['id']);
          if (soilResponse['success']) {
            final soilsData = soilResponse['soils'];
            if (soilsData is List) {
              compatibleSoils = soilsData.map((soil) {
                if (soil is Map<String, dynamic>) {
                  return soil;
                } else if (soil is Map) {
                  return Map<String, dynamic>.from(soil);
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
            }
          }
        } catch (e) {
          print('Error getting compatible soils: $e');
          compatibleSoils = null;
        }
      }

      // Step 4: ENHANCED - Automatically save analysis result if user is logged in
      Map<String, dynamic>? savedResult;
      if (_accessToken != null) {
        try {
          savedResult = await _saveAnalysisToDatabase(aiData, imagePath, matchedPlant);
          print('Analysis saved to database: $savedResult');
        } catch (e) {
          print('Error saving analysis to database: $e');
          // Don't fail the whole process if saving fails
          savedResult = null;
        }
      }

      // Step 5: Return enhanced data with proper type safety
      return {
        'success': true,
        'data': {
          // Keep original AI data structure
          'class': aiData['class']?.toString() ?? 'Unknown',
          'status': aiData['status']?.toString() ?? 'Unknown',
          'espece': aiData['espece']?.toString() ?? 'Unknown',
          'maladie': aiData['maladie']?.toString() ?? 'Unknown',
          'confidence': _safeToDouble(aiData['confidence'], 0.9),
          // Add database enhancements
          'matchedPlant': matchedPlant,
          'compatibleSoils': compatibleSoils,
          'savedResult': savedResult,
          'isConnectedToDatabase': true,
          'isUserAuthenticated': _accessToken != null,
        },
      };
    } catch (e) {
      print('Error in analyzePlantWithDatabase: $e');
      return {
        'success': false,
        'error': 'Analysis failed: $e',
        'mock_data': {
          'class': 'Tomato___healthy',
          'status': '✅ Plante saine (mode test)',
          'espece': 'Tomate',
          'maladie': 'Sain',
          'confidence': 0.85,
        },
      };
    }
  }

  // NEW: Get user's analysis history
  static Future<List<PlantAnalysisResult>> getUserAnalysisHistory() async {
    if (_accessToken == null) {
      print('No access token available for fetching analysis history');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/users/analysis-history/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> analysisData = json.decode(response.body);

        return analysisData.map((analysis) {
          final analysisMap = analysis as Map<String, dynamic>;

          // Convert database format to PlantAnalysisResult
          return PlantAnalysisResult(
            className: analysisMap['class_name']?.toString() ?? 'Unknown',
            status: analysisMap['status']?.toString() ?? 'Unknown',
            species: analysisMap['species']?.toString() ?? 'Unknown',
            disease: analysisMap['disease']?.toString() ?? 'Unknown',
            imagePath: analysisMap['image_path']?.toString() ?? '',
            analyzedAt: DateTime.tryParse(analysisMap['analyzed_at']?.toString() ?? '') ?? DateTime.now(),
            isHealthy: analysisMap['is_healthy'] ?? true,
            confidence: _safeToDouble(analysisMap['confidence'], 0.9),
            analysisId: analysisMap['id'],
            hasDatabase: true,
          );
        }).toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await _refreshAccessToken();
        if (refreshResult['success']) {
          return getUserAnalysisHistory(); // Retry with new token
        }
        print('Authentication expired when fetching analysis history');
        return [];
      } else {
        print('Failed to fetch analysis history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching analysis history: $e');
      return [];
    }
  }

  // NEW: Get user's analysis statistics
  static Future<Map<String, dynamic>> getUserAnalysisStatistics() async {
    if (_accessToken == null) {
      return {
        'success': false,
        'error': 'Not authenticated',
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/users/analysis-statistics/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await _refreshAccessToken();
        if (refreshResult['success']) {
          return getUserAnalysisStatistics();
        }
        return {
          'success': false,
          'error': 'Authentication expired',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch statistics: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // ENHANCED: Save analysis result to database
  static Future<Map<String, dynamic>?> _saveAnalysisToDatabase(
      Map<String, dynamic> aiData,
      String imagePath,
      Map<String, dynamic>? matchedPlant,
      ) async {
    if (_accessToken == null) {
      print('No access token available for saving analysis');
      return null;
    }

    try {
      final analysisData = {
        'species': aiData['espece']?.toString() ?? 'Unknown',
        'disease': aiData['maladie']?.toString() ?? 'Unknown',
        'status': aiData['status']?.toString() ?? 'Unknown',
        'confidence': _safeToDouble(aiData['confidence'], 0.9),
        'image_path': imagePath,
        'is_healthy': _isHealthyStatus(aiData['status']?.toString() ?? ''),
        'class_name': aiData['class']?.toString() ?? 'Unknown',
        'matched_plant_id': matchedPlant?['id'],
      };

      final response = await http.post(
        Uri.parse('$mainBaseUrl/users/save-analysis/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(analysisData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        final refreshResult = await _refreshAccessToken();
        if (refreshResult['success']) {
          return _saveAnalysisToDatabase(aiData, imagePath, matchedPlant);
        }
        print('Authentication expired when saving analysis');
        return null;
      } else {
        print('Failed to save analysis: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error saving analysis to database: $e');
      return null;
    }
  }

  static bool _isHealthyStatus(String status) {
    return status.contains('✅') ||
        status.toLowerCase().contains('sain') ||
        status.toLowerCase().contains('healthy');
  }

  // Helper method for safe double conversion
  static double _safeToDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  // Plant and Soil database methods
  static Future<List<dynamic>> getPlants() async {
    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/plants/'),
        headers: {
          'Accept': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else {
          return [];
        }
      } else {
        print('Failed to get plants: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting plants: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getSoils() async {
    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/soils/'),
        headers: {
          'Accept': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else {
          return [];
        }
      } else {
        print('Failed to get soils: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting soils: $e');
      return [];
    }
  }

  // Plant AI analysis with better error handling
  static Future<Map<String, dynamic>> _getPlantAiAnalysis(String imagePath) async {
    try {
      print('Sending image to AI service: $imagePath');

      // Verify file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return {
          'success': false,
          'error': 'Image file not found: $imagePath',
        };
      }

      final uri = Uri.parse('$plantAiBaseUrl/api/predict/');
      final request = http.MultipartRequest('POST', uri);

      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      print('Sending request to: $uri');

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('AI Response status: ${response.statusCode}');
      print('AI Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': true,
            'data': responseData,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to parse AI response: $e',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'AI analysis failed: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('Error in _getPlantAiAnalysis: $e');
      return {
        'success': false,
        'error': 'AI service error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> _findMatchingPlant(String species) async {
    try {
      final plants = await getPlants();

      // Try to find a matching plant in the database
      for (var plant in plants) {
        if (plant is! Map) continue;

        final plantName = plant['name']?.toString().toLowerCase() ?? '';
        final speciesLower = species.toLowerCase();

        // Simple matching logic - you can make this more sophisticated
        if (_isPlantMatch(plantName, speciesLower)) {
          if (plant is Map<String, dynamic>) {
            return plant;
          } else if (plant is Map) {
            return Map<String, dynamic>.from(plant);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error finding matching plant: $e');
      return null;
    }
  }

  static bool _isPlantMatch(String plantName, String species) {
    // Enhanced matching logic
    final matches = [
      // French/English tomato matches
      (plantName.contains('tomate') || plantName.contains('tomato')) &&
          (species.contains('tomate') || species.contains('tomato')),

      // French/English potato matches
      (plantName.contains('pomme') || plantName.contains('potato')) &&
          (species.contains('pomme') || species.contains('potato')),

      // French/English pepper matches
      (plantName.contains('poivron') || plantName.contains('pepper')) &&
          (species.contains('poivron') || species.contains('pepper')),

      // Exact name match
      plantName == species,

      // Partial match (at least 3 characters)
      species.length >= 3 && plantName.contains(species.substring(0, 3)),
    ];

    return matches.any((match) => match);
  }

  static Future<Map<String, dynamic>> _getSoilsForPlant(dynamic plantId) async {
    try {
      final id = plantId is int ? plantId : int.tryParse(plantId.toString());
      if (id == null) {
        return {
          'success': false,
          'error': 'Invalid plant ID',
        };
      }

      final response = await http.get(
        Uri.parse('$mainBaseUrl/plants/$id/soils/'),
        headers: {
          'Accept': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'soils': data['soils'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get compatible soils: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // User profile methods
  static Future<Map<String, dynamic>> getUserProfile() async {
    if (_accessToken == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/users/profile/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await _refreshAccessToken();
        if (refreshResult['success']) {
          return getUserProfile(); // Retry with new token
        }
        return {'success': false, 'error': 'Authentication expired'};
      } else {
        return {'success': false, 'error': 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _refreshAccessToken() async {
    if (_refreshToken == null) {
      return {'success': false, 'error': 'No refresh token'};
    }

    try {
      final response = await http.post(
        Uri.parse('$mainBaseUrl/users/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refresh': _refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access'];
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Token refresh failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Refresh error: $e'};
    }
  }

  static Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse('$mainBaseUrl/users/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: json.encode({'refresh': _refreshToken}),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Logout error: $e');
      }
    }

    _accessToken = null;
    _refreshToken = null;
  }

  // Backend connection testing
  static Future<bool> checkMainBackendConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/plants/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Main backend connection check failed: $e');
      return false;
    }
  }

  static Future<bool> checkPlantAiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$plantAiBaseUrl/api/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 404; // 404 is OK for base API endpoint
    } catch (e) {
      print('Plant AI backend connection check failed: $e');
      return false;
    }
  }

  // Utility methods
  static bool get isAuthenticated => _accessToken != null;
  static String? get accessToken => _accessToken;

  static void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
}