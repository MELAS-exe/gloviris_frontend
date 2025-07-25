import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainBackendService {
  // Main Django backend (spacehack2) - update with your actual IP
  static const String mainBaseUrl = 'http://172.16.16.109:8000'; // Update this

  // Plant AI backend - update with your actual IP
  static const String plantAiBaseUrl = 'http://172.16.16.109:8001'; // Different port

  static String? _accessToken;
  static String? _refreshToken;

  // Authentication methods
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
      );

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
      );

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

  // Plant AI Analysis integrated with database
  static Future<Map<String, dynamic>> analyzePlantWithDatabase(String imagePath) async {
    try {
      // Step 1: Get AI analysis from plant AI backend
      final aiResult = await _getPlantAiAnalysis(imagePath);

      if (!aiResult['success']) {
        return aiResult;
      }

      // Step 2: Try to match with database plants
      final matchedPlant = await _findMatchingPlant(aiResult['data']['espece']);

      // Step 3: Get compatible soils if plant matched
      List<Map<String, dynamic>>? compatibleSoils;
      if (matchedPlant != null) {
        try {
          final soilResponse = await _getSoilsForPlant(matchedPlant['id']);
          if (soilResponse['success']) {
            compatibleSoils = List<Map<String, dynamic>>.from(soilResponse['soils']);
          }
        } catch (e) {
          print('Error getting compatible soils: $e');
        }
      }

      // Step 4: Save analysis result if user is logged in
      Map<String, dynamic>? savedResult;
      if (_accessToken != null) {
        savedResult = await _saveAnalysisResult(aiResult['data'], imagePath, matchedPlant);
      }

      // Step 5: Return enhanced data that works with existing PlantAnalysisResult
      return {
        'success': true,
        'data': {
          // Keep original AI data structure
          ...aiResult['data'],
          // Add database enhancements
          'matchedPlant': matchedPlant,
          'compatibleSoils': compatibleSoils,
          'savedResult': savedResult,
          'isConnectedToDatabase': true,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Analysis failed: $e',
      };
    }
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
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
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
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get soils: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting soils: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> _getPlantAiAnalysis(String imagePath) async {
    try {
      final uri = Uri.parse('$plantAiBaseUrl/api/predict/');
      final request = http.MultipartRequest('POST', uri);

      final file = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(file);
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'AI analysis failed: ${response.statusCode}',
        };
      }
    } catch (e) {
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
        final plantName = plant['name']?.toString().toLowerCase() ?? '';
        final speciesLower = species.toLowerCase();

        // Simple matching logic - you can make this more sophisticated
        if (plantName.contains('tomate') && speciesLower.contains('tomate') ||
            plantName.contains('tomato') && speciesLower.contains('tomate') ||
            plantName.contains('pomme') && speciesLower.contains('pomme') ||
            plantName.contains('potato') && speciesLower.contains('pomme') ||
            plantName.contains('poivron') && speciesLower.contains('poivron') ||
            plantName.contains('pepper') && speciesLower.contains('poivron')) {
          return plant;
        }
      }
      return null;
    } catch (e) {
      print('Error finding matching plant: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _getSoilsForPlant(int plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$mainBaseUrl/plants/$plantId/soils/'),
        headers: {
          'Accept': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'soils': data['soils'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get compatible soils',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> _saveAnalysisResult(
      Map<String, dynamic> aiData,
      String imagePath,
      Map<String, dynamic>? matchedPlant,
      ) async {
    // This would save to your backend - you might need to create a new endpoint
    // For now, we'll just return the data structure
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'user_id': 'current_user', // Get from auth token
      'species': aiData['espece'],
      'disease': aiData['maladie'],
      'status': aiData['status'],
      'confidence': aiData['confidence'] ?? 0.9,
      'image_path': imagePath,
      'matched_plant_id': matchedPlant?['id'],
      'analyzed_at': DateTime.now().toIso8601String(),
    };
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
      );

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
      );

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
        );
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