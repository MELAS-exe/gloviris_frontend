// lib/models/plant_analysis_result.dart
// Fixed version to handle type casting issues

import '../services/plant_ai_service.dart';

class PlantAnalysisResult {
  final String className;
  final String status;
  final String species;
  final String disease;
  final String imagePath;
  final DateTime analyzedAt;
  final bool isHealthy;

  // Enhanced fields for database integration (optional)
  final double? confidence;
  final Map<String, dynamic>? matchedPlant;
  final List<Map<String, dynamic>>? compatibleSoils;
  final String? userId;
  final int? analysisId;
  final bool hasDatabase;

  PlantAnalysisResult({
    required this.className,
    required this.status,
    required this.species,
    required this.disease,
    required this.imagePath,
    required this.analyzedAt,
    required this.isHealthy,
    this.confidence,
    this.matchedPlant,
    this.compatibleSoils,
    this.userId,
    this.analysisId,
    this.hasDatabase = false,
  });

  // FIXED: Updated factory method with proper type casting
  factory PlantAnalysisResult.fromJson(dynamic jsonData, String imagePath) {
    // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
    Map<String, dynamic> json;

    if (jsonData is Map<String, dynamic>) {
      json = jsonData;
    } else if (jsonData is Map) {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      json = Map<String, dynamic>.from(jsonData);
    } else {
      // Fallback for other types
      json = {};
    }

    final status = json['status']?.toString() ?? '';
    final isHealthy = status.contains('✅') ||
        status.toLowerCase().contains('sain') ||
        status.toLowerCase().contains('healthy');

    // Safe type conversion for lists
    List<Map<String, dynamic>>? compatibleSoils;
    if (json['compatibleSoils'] != null) {
      try {
        final soilsData = json['compatibleSoils'];
        if (soilsData is List) {
          compatibleSoils = soilsData.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              return <String, dynamic>{};
            }
          }).toList();
        }
      } catch (e) {
        print('Error parsing compatible soils: $e');
        compatibleSoils = null;
      }
    }

    // Safe type conversion for matched plant
    Map<String, dynamic>? matchedPlant;
    if (json['matchedPlant'] != null) {
      try {
        final plantData = json['matchedPlant'];
        if (plantData is Map<String, dynamic>) {
          matchedPlant = plantData;
        } else if (plantData is Map) {
          matchedPlant = Map<String, dynamic>.from(plantData);
        }
      } catch (e) {
        print('Error parsing matched plant: $e');
        matchedPlant = null;
      }
    }

    // Safe type conversion for saved result
    Map<String, dynamic>? savedResult;
    if (json['savedResult'] != null) {
      try {
        final resultData = json['savedResult'];
        if (resultData is Map<String, dynamic>) {
          savedResult = resultData;
        } else if (resultData is Map) {
          savedResult = Map<String, dynamic>.from(resultData);
        }
      } catch (e) {
        print('Error parsing saved result: $e');
        savedResult = null;
      }
    }

    return PlantAnalysisResult(
      className: json['class']?.toString() ?? 'Unknown',
      status: status,
      species: json['espece']?.toString() ?? 'Unknown',
      disease: json['maladie']?.toString() ?? 'Unknown',
      imagePath: imagePath,
      analyzedAt: DateTime.now(),
      isHealthy: isHealthy,
      // Enhanced fields with safe casting
      confidence: _safeToDouble(json['confidence'], 0.9),
      matchedPlant: matchedPlant,
      compatibleSoils: compatibleSoils,
      userId: savedResult?['user_id']?.toString(),
      analysisId: _safeToInt(savedResult?['id']),
      hasDatabase: json['isConnectedToDatabase'] == true,
    );
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

  // Helper method for safe int conversion
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'status': status,
      'species': species,
      'disease': disease,
      'imagePath': imagePath,
      'analyzedAt': analyzedAt.toIso8601String(),
      'isHealthy': isHealthy,
      'confidence': confidence,
      'matchedPlant': matchedPlant,
      'compatibleSoils': compatibleSoils,
      'userId': userId,
      'analysisId': analysisId,
      'hasDatabase': hasDatabase,
    };
  }

  // Get health status color
  String get healthStatusColor {
    if (isHealthy) return 'green';
    if (disease.toLowerCase().contains('bacterial') ||
        disease.toLowerCase().contains('virus')) return 'red';
    return 'orange'; // For other diseases
  }

  // Enhanced recommendations including database data
  List<String> get recommendations {
    return PlantApiService.getEnhancedRecommendations({
      'status': status,
      'maladie': disease,
      'matchedPlant': matchedPlant,
      'compatibleSoils': compatibleSoils,
      'confidence': confidence,
    });
  }

  // Get compatible soils for this plant species
  List<String> get compatibleSoilNames {
    if (compatibleSoils == null) return [];
    return compatibleSoils!.map((soil) => soil['name']?.toString() ?? 'Unknown').toList();
  }

  // Get plant care information from database
  String? get plantCareInfo {
    return matchedPlant?['description']?.toString();
  }

  // Get severity level
  String get severityLevel {
    if (isHealthy) return 'Aucun';

    if (disease.toLowerCase().contains('virus') ||
        disease.toLowerCase().contains('bacterial')) {
      return 'Élevé';
    }

    if (disease.toLowerCase().contains('blight') ||
        disease.toLowerCase().contains('spot')) {
      return 'Moyen';
    }

    return 'Faible';
  }

  // Get treatment urgency
  String get treatmentUrgency {
    if (isHealthy) return 'Aucune';

    switch (severityLevel) {
      case 'Élevé':
        return 'Immédiate (24-48h)';
      case 'Moyen':
        return 'Rapide (1-3 jours)';
      case 'Faible':
        return 'Modérée (1 semaine)';
      default:
        return 'À évaluer';
    }
  }

  // Check if expert consultation is recommended
  bool get needsExpertConsultation {
    return !isHealthy && (
        severityLevel == 'Élevé' ||
            (confidence != null && confidence! < 0.7) ||
            disease.toLowerCase().contains('virus')
    );
  }

  // Get confidence level as percentage
  String get confidencePercentage {
    if (confidence == null) return '90%';
    return '${(confidence! * 100).round()}%';
  }

  // Check if this analysis has database enhancements
  bool get isDatabaseEnhanced {
    return hasDatabase && (matchedPlant != null || (compatibleSoils != null && compatibleSoils!.isNotEmpty));
  }
}