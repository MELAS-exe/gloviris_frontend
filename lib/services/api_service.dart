import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual backend URL
  static const String baseUrl = 'https://your-backend-api.com';

  static Future<Map<String, dynamic>> analyzeSoilImage(String imagePath) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze-soil');
      final request = http.MultipartRequest('POST', uri);

      // Add the image file
      final file = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        filename: 'soil_sample.jpg',
      );
      request.files.add(file);

      // Add any additional metadata
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      request.fields['device_id'] = 'flutter_app';

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to analyze soil: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return mock data if API fails
      return _getMockAnalysisResult();
    }
  }

  static Map<String, dynamic> _getMockAnalysisResult() {
    // Mock response for demonstration
    return {
      'soilType': 'Clay Loam',
      'phLevel': '6.8',
      'moisture': '45%',
      'nutrients': 'High in Nitrogen, Medium Phosphorus',
      'recommendations': [
        'Suitable for corn and wheat',
        'Consider adding organic matter',
        'Good drainage recommended'
      ],
      'confidence': 0.87,
    };
  }
}