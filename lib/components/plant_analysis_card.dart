import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gloviris_app/models/plant_data.dart';
import '../models/plant_analysis_result.dart';
import '../screens/PlantResultScreen.dart';
import '../theme/app_theme.dart';

class PlantAnalysisCard extends StatelessWidget {
  final PlantData plantData;

  const PlantAnalysisCard({
    super.key,
    required this.plantData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _navigateToResultScreen(context);
              },
              child: Text(
                plantData.plantName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.badgeBackground,
                    ),
                    child: _buildImageWidget(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHealthStatusBadge(),
                      const SizedBox(height: 10),
                      _buildDiseaseNameBadge(),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      _navigateToResultScreen(context);
                    },
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Check if this is a network image or local image path
    if (plantData.plantImage.startsWith('http')) {
      // Network image
      return Image.network(
        plantData.plantImage,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
          return const Icon(
            Icons.image_not_supported,
            size: 40,
            color: AppTheme.textSecondary,
          );
        },
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else if (plantData.plantImage.isNotEmpty && !plantData.plantImage.startsWith('/mock/')) {
      // Local image file
      try {
        return Image.file(
          File(plantData.plantImage),
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return const Icon(
              Icons.eco,
              size: 40,
              color: AppTheme.primaryGreen,
            );
          },
        );
      } catch (e) {
        return const Icon(
          Icons.eco,
          size: 40,
          color: AppTheme.primaryGreen,
        );
      }
    } else {
      // Default icon for mock or empty images
      return const Icon(
        Icons.eco,
        size: 40,
        color: AppTheme.primaryGreen,
      );
    }
  }

  void _navigateToResultScreen(BuildContext context) {
    try {
      // Convert PlantData to PlantAnalysisResult for the result screen
      final analysisResult = PlantAnalysisResult(
        className: _mapHealthStatusToClassName(plantData.healthStatus),
        status: _mapHealthStatusToStatusMessage(plantData.healthStatus),
        species: plantData.plantName,
        disease: plantData.diseaseName,
        imagePath: plantData.plantImage,
        analyzedAt: DateTime.now(), // Use current time if not available
        isHealthy: _isHealthyStatus(plantData.healthStatus),
        confidence: 0.85, // Default confidence
        hasDatabase: true,
      );

      // Add custom recommendations based on the plant data
      final customRecommendations = _getCustomRecommendations();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantResultScreen(
            analysisResult: analysisResult,
            isMockData: plantData.plantImage.contains('/mock/') ||
                plantData.plantImage.startsWith('assets/'),
          ),
        ),
      );
    } catch (e) {
      // Show error dialog if navigation fails
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Erreur',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            content: Text('Impossible d\'afficher les détails: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  List<String> _getCustomRecommendations() {
    if (_isHealthyStatus(plantData.healthStatus)) {
      return [
        'Continuez les soins actuels',
        'Surveillez régulièrement l\'état de la plante',
        'Maintenez un arrosage approprié',
        'Assurez-vous d\'une bonne exposition à la lumière',
      ];
    } else {
      // Get recommendations from the plant data or create based on disease
      final solutions = plantData.diseaseSolutions;
      if (solutions.isNotEmpty && solutions != 'Unknown') {
        return solutions.split('\n').where((s) => s.trim().isNotEmpty).toList();
      } else {
        return _getDefaultDiseaseRecommendations(plantData.diseaseName);
      }
    }
  }

  List<String> _getDefaultDiseaseRecommendations(String disease) {
    if (disease.toLowerCase().contains('bacterial') ||
        disease.toLowerCase().contains('bactérien')) {
      return [
        'Retirez immédiatement les parties infectées',
        'Améliorez la circulation d\'air',
        'Évitez l\'arrosage sur les feuilles',
        'Appliquez un traitement antibactérien',
      ];
    } else if (disease.toLowerCase().contains('tache')) {
      return [
        'Retirez les feuilles tachées',
        'Améliorez la ventilation',
        'Appliquez un fongicide préventif',
        'Évitez l\'humidité excessive',
      ];
    } else {
      return [
        'Consultez un expert en agriculture',
        'Surveillez l\'évolution des symptômes',
        'Améliorez les conditions de culture',
        'Isolez la plante si nécessaire',
      ];
    }
  }

  String _mapHealthStatusToClassName(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case "healthy":
      case "sain":
        return "Plant___healthy";
      case "sick":
      case "diseased":
      case "malade":
        return "Plant___diseased";
      default:
        return "Plant___unknown";
    }
  }

  String _mapHealthStatusToStatusMessage(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case "healthy":
      case "sain":
        return "✅ Plante saine";
      case "sick":
      case "diseased":
      case "malade":
        return "❌ Plante malade";
      default:
        return "⚠️ État à vérifier";
    }
  }

  bool _isHealthyStatus(String healthStatus) {
    return healthStatus.toLowerCase() == "healthy" ||
        healthStatus.toLowerCase() == "sain";
  }

  Color _getHealthStatusColor(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case "sick":
      case "diseased":
      case "malade":
        return Colors.red;
      case "healthy":
      case "sain":
        return Colors.green;
      case "unknown":
      default:
        return Colors.orange;
    }
  }

  Widget _buildHealthStatusBadge() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.badgeBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _getHealthStatusColor(plantData.healthStatus)),
          ),
          const SizedBox(width: 8),
          Text(
            plantData.healthStatus,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseNameBadge() {
    return Container(
        height: 30,
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.badgeBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(
              plantData.diseaseName,
              overflow: TextOverflow.ellipsis,
            )]));
  }
}