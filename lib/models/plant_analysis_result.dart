// Extension to your existing PlantAnalysisResult class
// This adds database integration features without changing the original class

import '../services/plant_ai_service.dart';

class PlantAnalysisResult {
  final String className;
  final String status;
  final String species;
  final String disease;
  final String imagePath;
  final DateTime analyzedAt;
  final bool isHealthy;

  // New fields for database integration (optional)
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

  // Updated factory method that handles both basic and enhanced data
  factory PlantAnalysisResult.fromJson(Map<String, dynamic> json, String imagePath) {
    final status = json['status'] ?? '';
    final isHealthy = status.contains('✅') || status.toLowerCase().contains('sain');

    return PlantAnalysisResult(
      className: json['class'] ?? 'Unknown',
      status: status,
      species: json['espece'] ?? 'Unknown',
      disease: json['maladie'] ?? 'Unknown',
      imagePath: imagePath,
      analyzedAt: DateTime.now(),
      isHealthy: isHealthy,
      // Enhanced fields
      confidence: (json['confidence'] ?? 0.9).toDouble(),
      matchedPlant: json['matchedPlant'],
      compatibleSoils: json['compatibleSoils'] != null
          ? List<Map<String, dynamic>>.from(json['compatibleSoils'])
          : null,
      userId: json['savedResult']?['user_id'],
      analysisId: json['savedResult']?['id'],
      hasDatabase: json['isConnectedToDatabase'] ?? false,
    );
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
    return compatibleSoils!.map((soil) => soil['name'].toString()).toList();
  }

  // Get plant care information from database
  String? get plantCareInfo {
    return matchedPlant?['description'];
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