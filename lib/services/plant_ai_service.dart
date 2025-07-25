// lib/services/plant_ai_service.dart
// Fixed version with better error handling and type safety

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_data.dart';
import 'main_backend_service.dart';

class PlantApiService {
  // Enhanced analysis method that includes database integration
  static Future<Map<String, dynamic>> analyzePlantImage(String imagePath) async {
    print('Starting plant image analysis for: $imagePath');

    try {
      // Verify file exists and is accessible
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      // Check file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file too large (max 10MB)');
      }

      // Try the integrated backend service first
      final result = await MainBackendService.analyzePlantWithDatabase(imagePath);
      print('Backend analysis result: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
          'hasDatabase': result['data']?['isConnectedToDatabase'] ?? false,
          'matchedPlant': result['data']?['matchedPlant'],
          'compatibleSoils': result['data']?['compatibleSoils'],
        };
      } else {
        // If integrated service fails, try basic analysis
        print('Integrated service failed, trying basic analysis...');
        return await _tryBasicAnalysis(imagePath, result);
      }
    } catch (e) {
      print('Error analyzing plant: $e');
      // Return mock data for development/testing
      return _getMockAnalysisResult(e.toString());
    }
  }

  // Backward compatibility method
  static Future<Map<String, dynamic>> analyzeSoilImage(String imagePath) async {
    // Redirect to the enhanced plant analysis
    return await analyzePlantImage(imagePath);
  }

  // Try basic analysis without database integration
  static Future<Map<String, dynamic>> _tryBasicAnalysis(String imagePath, Map<String, dynamic> previousResult) async {
    try {
      // Direct call to plant AI service
      final result = await _callPlantAiDirectly(imagePath);

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
          'hasDatabase': false,
          'note': 'Basic analysis only - database unavailable',
        };
      } else {
        throw Exception('Basic analysis also failed: ${result['error']}');
      }
    } catch (e) {
      print('Basic analysis failed: $e');

      // Return the original error with mock data
      return {
        'success': false,
        'error': previousResult['error'] ?? e.toString(),
        'mock_data': previousResult['mock_data'] ?? _getDefaultMockData(),
      };
    }
  }

  // Direct call to Plant AI service
  static Future<Map<String, dynamic>> _callPlantAiDirectly(String imagePath) async {
    try {
      const String plantAiBaseUrl = 'http://172.16.16.109:8001'; // Update with your IP

      final uri = Uri.parse('$plantAiBaseUrl/api/predict/');
      final request = http.MultipartRequest('POST', uri);

      final file = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(file);
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Plant AI service failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Direct AI call failed: $e',
      };
    }
  }

  static Map<String, dynamic> _getMockAnalysisResult(String error) {
    return {
      'success': false,
      'error': 'Analysis failed: $error',
      'mock_data': _getDefaultMockData(),
    };
  }

  static Map<String, dynamic> _getDefaultMockData() {
    return {
      'class': 'Tomato___healthy',
      'status': '✅ Plante saine (données de test)',
      'espece': 'Tomate',
      'maladie': 'Sain',
      'confidence': 0.85,
    };
  }

  // Helper method to check if backend is reachable
  static Future<bool> checkBackendConnection() async {
    final mainBackend = await MainBackendService.checkMainBackendConnection();
    final aiBackend = await MainBackendService.checkPlantAiConnection();

    return mainBackend || aiBackend; // Return true if at least one is connected
  }

  // Get enhanced recommendations based on database integration
  static List<String> getEnhancedRecommendations(Map<String, dynamic> analysisData) {
    List<String> recommendations = [];

    try {
      final isHealthy = _isPlantHealthy(analysisData);
      final disease = analysisData['maladie']?.toString() ?? '';
      final matchedPlant = analysisData['matchedPlant'];
      final compatibleSoils = analysisData['compatibleSoils'];

      if (isHealthy) {
        recommendations.addAll([
          'Continuez les soins réguliers',
          'Maintenez un arrosage approprié',
          'Surveillez régulièrement les signes de maladie',
          'Fertilisez selon les besoins de la plante',
        ]);

        // Add database-specific recommendations
        if (matchedPlant != null) {
          final plantName = matchedPlant['name']?.toString() ?? 'cette plante';
          recommendations.add('📋 Consultez la fiche complète de $plantName dans notre base de données');
        }

        if (compatibleSoils != null && compatibleSoils is List && compatibleSoils.isNotEmpty) {
          final soilNames = compatibleSoils
              .take(2)
              .map((s) => s is Map ? s['name']?.toString() ?? 'Sol' : 'Sol')
              .join(', ');
          recommendations.add('🌱 Sols recommandés: $soilNames');
        }

        return recommendations;
      }

      // Disease-specific recommendations
      recommendations.addAll(_getDiseaseSpecificRecommendations(disease));

      // Add database-enhanced recommendations
      if (matchedPlant != null) {
        final plantName = matchedPlant['name']?.toString() ?? 'cette plante';
        recommendations.add('📋 Consultez les soins spécifiques pour $plantName dans notre base');
      }

      if (compatibleSoils != null && compatibleSoils is List && compatibleSoils.isNotEmpty) {
        final soilNames = compatibleSoils
            .take(2)
            .map((s) => s is Map ? s['name']?.toString() ?? 'Sol' : 'Sol')
            .join(', ');
        recommendations.add('🌱 Vérifiez si votre sol est adapté: $soilNames');
      }

      // Add urgency-based recommendations
      final confidence = _safeToDouble(analysisData['confidence'], 0.9);
      if (!isHealthy && confidence > 0.8) {
        recommendations.insert(0, '⚠️ Diagnostic fiable (${(confidence * 100).round()}%) - Action rapide recommandée');
      }

    } catch (e) {
      print('Error generating recommendations: $e');
      recommendations.add('Consultez un expert en agriculture pour des conseils spécialisés');
    }

    return recommendations;
  }

  static bool _isPlantHealthy(Map<String, dynamic> analysisData) {
    final status = analysisData['status']?.toString() ?? '';
    return status.contains('✅') ||
        status.toLowerCase().contains('sain') ||
        status.toLowerCase().contains('healthy');
  }

  static List<String> _getDiseaseSpecificRecommendations(String disease) {
    final diseaseLower = disease.toLowerCase();

    if (diseaseLower.contains('bacterial') || diseaseLower.contains('bactérien')) {
      return [
        '🚨 Retirez immédiatement les feuilles infectées',
        'Améliorez la circulation d\'air autour de la plante',
        'Évitez l\'arrosage sur les feuilles',
        'Appliquez un traitement antibactérien si nécessaire',
        'Désinfectez vos outils de jardinage',
      ];
    } else if (diseaseLower.contains('virus')) {
      return [
        '🚨 Isolez immédiatement la plante infectée',
        'Retirez et brûlez les parties infectées',
        'Contrôlez les insectes vecteurs (pucerons, thrips)',
        'Désinfectez tous les outils utilisés',
        'Surveillez les plantes voisines',
      ];
    } else if (diseaseLower.contains('blight') || diseaseLower.contains('brûlure')) {
      return [
        'Améliorez le drainage du sol',
        'Réduisez l\'humidité autour de la plante',
        'Appliquez un fongicide préventif',
        'Espacez mieux les plants pour une meilleure aération',
        'Évitez l\'arrosage en soirée',
      ];
    } else if (diseaseLower.contains('mold') || diseaseLower.contains('moisi')) {
      return [
        'Améliorez la ventilation',
        'Réduisez l\'humidité ambiante',
        'Retirez les feuilles affectées',
        'Appliquez un fongicide adapté',
      ];
    } else if (diseaseLower.contains('spot') || diseaseLower.contains('tache')) {
      return [
        'Retirez les feuilles tachées',
        'Améliorez la circulation d\'air',
        'Évitez l\'arrosage par aspersion',
        'Appliquez un traitement fongicide préventif',
      ];
    } else {
      // Generic recommendations
      return [
        'Consultez un expert en agriculture',
        'Retirez les parties infectées',
        'Améliorez les conditions de croissance',
        'Surveillez l\'évolution de la maladie',
      ];
    }
  }

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

  // Convert analysis data to existing PlantData model for compatibility
  static PlantData convertToPlantData(Map<String, dynamic> analysisData, String imagePath) {
    try {
      final recommendations = getEnhancedRecommendations(analysisData);
      final isHealthy = _isPlantHealthy(analysisData);

      return PlantData(
        imagePath, // plantImage
        analysisData['espece']?.toString() ?? 'Unknown', // plantName
        isHealthy ? "Healthy" : "Diseased", // healthStatus
        analysisData['maladie']?.toString() ?? 'Unknown', // diseaseName
        _getDetectedDiseaseDescription(analysisData['maladie']?.toString() ?? ''), // diseaseDescription
        recommendations.join('\n• '), // diseaseSolutions
      );
    } catch (e) {
      print('Error converting to PlantData: $e');
      return PlantData(
        imagePath,
        'Unknown',
        'Unknown',
        'Analysis Error',
        'Error processing analysis results',
        'Please try again or consult an expert',
      );
    }
  }

  static String _getDetectedDiseaseDescription(String disease) {
    final descriptions = {
      'Bacterial spot': 'Taches bactériennes causant des lésions sur les feuilles et les fruits.',
      'Early blight': 'Maladie fongique provoquant des taches brunes concentriques sur les feuilles.',
      'Late blight': 'Maladie fongique grave pouvant détruire rapidement la plante.',
      'Leaf Mold': 'Moisissure des feuilles causée par un champignon, commune en serre.',
      'Septoria leaf spot': 'Taches foliaires causées par un champignon, affectant principalement les feuilles inférieures.',
      'Spider mites': 'Acariens causant des décolorations et des toiles fines sur les feuilles.',
      'Target Spot': 'Taches circulaires avec anneaux concentriques sur les feuilles.',
      'Yellow Leaf Curl Virus': 'Virus causant l\'enroulement et le jaunissement des feuilles.',
      'Mosaic virus': 'Virus provoquant une mosaïque de couleurs sur les feuilles.',
      'Sain': 'Plante en bonne santé sans signes de maladie détectée.',
    };

    for (String key in descriptions.keys) {
      if (disease.toLowerCase().contains(key.toLowerCase())) {
        return descriptions[key]!;
      }
    }

    return 'Maladie détectée par analyse IA. Consultez les recommandations pour le traitement.';
  }
}