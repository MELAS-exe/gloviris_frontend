import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_data.dart';
import 'main_backend_service.dart';

class PlantApiService {
  // This now uses the MainBackendService for integrated analysis
  static Future<Map<String, dynamic>> analyzeSoilImage(String imagePath) async {
    // Keep this method for backward compatibility
    try {
      // Use the integrated backend service
      final result = await MainBackendService.analyzePlantWithDatabase(imagePath);
      return result;
    } catch (e) {
      print('Error analyzing plant: $e');
      // Return mock data for development/testing
      return _getMockAnalysisResult();
    }
  }

  // Enhanced analysis method that includes database integration
  static Future<Map<String, dynamic>> analyzePlantImage(String imagePath) async {
    try {
      final result = await MainBackendService.analyzePlantWithDatabase(imagePath);

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
          'hasDatabase': result['data']['isConnectedToDatabase'] ?? false,
          'matchedPlant': result['data']['matchedPlant'],
          'compatibleSoils': result['data']['compatibleSoils'],
        };
      } else {
        throw Exception('Analysis failed: ${result['error']}');
      }
    } catch (e) {
      print('Error analyzing plant: $e');
      // Return mock data for development/testing
      return _getMockAnalysisResult();
    }
  }

  static Map<String, dynamic> _getMockAnalysisResult() {
    // Mock response for demonstration when API is not available
    return {
      'success': false,
      'error': 'API connection failed',
      'mock_data': {
        'class': 'Tomato___healthy',
        'status': '✅ Plante saine',
        'espece': 'Tomate',
        'maladie': 'Sain',
        'confidence': 0.85,
      }
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

    final isHealthy = analysisData['status']?.contains('✅') ?? false;
    final disease = analysisData['maladie'] ?? '';
    final matchedPlant = analysisData['matchedPlant'];
    final compatibleSoils = analysisData['compatibleSoils'] as List<dynamic>?;

    if (isHealthy) {
      recommendations.addAll([
        'Continuez les soins réguliers',
        'Maintenez un arrosage approprié',
        'Surveillez régulièrement les signes de maladie',
      ]);

      // Add database-specific recommendations
      if (matchedPlant != null) {
        recommendations.add('📋 Consultez la fiche complète de ${matchedPlant['name']} dans notre base de données');
      }

      if (compatibleSoils != null && compatibleSoils.isNotEmpty) {
        final soilNames = compatibleSoils.map((s) => s['name']).take(2).join(', ');
        recommendations.add('🌱 Sols recommandés: $soilNames');
      }

      return recommendations;
    }

    // Disease-specific recommendations
    if (disease.toLowerCase().contains('bacterial')) {
      recommendations.addAll([
        '🚨 Retirez immédiatement les feuilles infectées',
        'Améliorez la circulation d\'air autour de la plante',
        'Évitez l\'arrosage sur les feuilles',
        'Appliquez un traitement antibactérien si nécessaire',
        'Désinfectez vos outils de jardinage',
      ]);
    } else if (disease.toLowerCase().contains('virus')) {
      recommendations.addAll([
        '🚨 Isolez immédiatement la plante infectée',
        'Retirez et brûlez les parties infectées',
        'Contrôlez les insectes vecteurs (pucerons, thrips)',
        'Désinfectez tous les outils utilisés',
        'Surveillez les plantes voisines',
      ]);
    } else if (disease.toLowerCase().contains('blight') || disease.toLowerCase().contains('brûlure')) {
      recommendations.addAll([
        'Améliorez le drainage du sol',
        'Réduisez l\'humidité autour de la plante',
        'Appliquez un fongicide préventif',
        'Espacez mieux les plants pour une meilleure aération',
        'Évitez l\'arrosage en soirée',
      ]);
    } else if (disease.toLowerCase().contains('mold') || disease.toLowerCase().contains('moisi')) {
      recommendations.addAll([
        'Améliorez la ventilation',
        'Réduisez l\'humidité ambiante',
        'Retirez les feuilles affectées',
        'Appliquez un fongicide adapté',
      ]);
    } else {
      // Generic recommendations
      recommendations.addAll([
        'Consultez un expert en agriculture',
        'Retirez les parties infectées',
        'Améliorez les conditions de croissance',
        'Surveillez l\'évolution de la maladie',
      ]);
    }

    // Add database-enhanced recommendations
    if (matchedPlant != null) {
      recommendations.add('📋 Consultez les soins spécifiques pour ${matchedPlant['name']} dans notre base');
    }

    if (compatibleSoils != null && compatibleSoils.isNotEmpty) {
      final soilNames = compatibleSoils.map((s) => s['name']).take(2).join(', ');
      recommendations.add('🌱 Vérifiez si votre sol est adapté: $soilNames');
    }

    // Add urgency-based recommendations
    final confidence = (analysisData['confidence'] ?? 0.9).toDouble();
    if (!isHealthy && confidence > 0.8) {
      recommendations.insert(0, '⚠️ Diagnostic fiable (${(confidence * 100).round()}%) - Action rapide recommandée');
    }

    return recommendations;
  }

  // Convert analysis data to existing PlantData model for compatibility
  static PlantData convertToPlantData(Map<String, dynamic> analysisData, String imagePath) {
    final recommendations = getEnhancedRecommendations(analysisData);
    final isHealthy = analysisData['status']?.contains('✅') ?? false;

    return PlantData(
      imagePath, // plantImage
      analysisData['espece'] ?? 'Unknown', // plantName
      isHealthy ? "Healthy" : "Diseased", // healthStatus
      analysisData['maladie'] ?? 'Unknown', // diseaseName
      _getDetectedDiseaseDescription(analysisData['maladie'] ?? ''), // diseaseDescription
      recommendations.join('\n• '), // diseaseSolutions
    );
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