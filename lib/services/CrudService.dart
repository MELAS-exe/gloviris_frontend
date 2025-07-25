// lib/services/crud_service.dart
// Service for all CRUD operations with the Django backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_data.dart';
import '../models/soil_data.dart';
import '../models/plant_analysis_result.dart';
import 'main_backend_service.dart';

class CrudService {
  static const String baseUrl = 'http://172.16.16.109:8000'; // Update with your IP

  // Plant CRUD Operations
  static Future<List<PlantData>> getAllPlants() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (MainBackendService.accessToken != null)
            'Authorization': 'Bearer ${MainBackendService.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> plantsJson = json.decode(response.body);

        return plantsJson.map((plantJson) {
          final plant = plantJson as Map<String, dynamic>;
          return PlantData(
            plant['image']?.toString() ?? '',
            plant['name']?.toString() ?? 'Unknown Plant',
            'Healthy', // Default status
            'N/A', // No disease by default
            plant['description']?.toString() ?? 'No description available',
            'Regular care and monitoring recommended',
          );
        }).toList();
      } else {
        print('Failed to fetch plants: ${response.statusCode}');
        return _getMockPlants();
      }
    } catch (e) {
      print('Error fetching plants: $e');
      return _getMockPlants();
    }
  }

  static Future<PlantData?> getPlantById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (MainBackendService.accessToken != null)
            'Authorization': 'Bearer ${MainBackendService.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> plantJson = json.decode(response.body);

        return PlantData(
          plantJson['image']?.toString() ?? '',
          plantJson['name']?.toString() ?? 'Unknown Plant',
          'Healthy',
          'N/A',
          plantJson['description']?.toString() ?? 'No description available',
          'Regular care and monitoring recommended',
        );
      } else {
        print('Failed to fetch plant: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching plant: $e');
      return null;
    }
  }

  // Soil CRUD Operations
  static Future<List<SoilData>> getAllSoils() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/soils/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (MainBackendService.accessToken != null)
            'Authorization': 'Bearer ${MainBackendService.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> soilsJson = json.decode(response.body);

        return soilsJson.map((soilJson) {
          final soil = soilJson as Map<String, dynamic>;

          // Extract crops from the soil data
          List<CropData> crops = [];
          if (soil['plants'] != null && soil['plants'] is List) {
            crops = (soil['plants'] as List).map((plant) {
              final plantMap = plant as Map<String, dynamic>;
              return CropData(
                icon: plantMap['image']?.toString() ?? '',
                name: plantMap['name']?.toString() ?? 'Unknown',
              );
            }).toList();
          }

          return SoilData(
            title: soil['name']?.toString() ?? 'Unknown Soil',
            soilType: _extractSoilType(soil['name']?.toString() ?? ''),
            soilImage: soil['image']?.toString(),
            soilIcon: 'assets/images/argile.png', // Default icon
            crops: crops,
          );
        }).toList();
      } else {
        print('Failed to fetch soils: ${response.statusCode}');
        return _getMockSoils();
      }
    } catch (e) {
      print('Error fetching soils: $e');
      return _getMockSoils();
    }
  }

  static Future<SoilData?> getSoilById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/soils/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (MainBackendService.accessToken != null)
            'Authorization': 'Bearer ${MainBackendService.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> soilJson = json.decode(response.body);

        // Extract crops from the soil data
        List<CropData> crops = [];
        if (soilJson['plants'] != null && soilJson['plants'] is List) {
          crops = (soilJson['plants'] as List).map((plant) {
            final plantMap = plant as Map<String, dynamic>;
            return CropData(
              icon: plantMap['image']?.toString() ?? '',
              name: plantMap['name']?.toString() ?? 'Unknown',
            );
          }).toList();
        }

        return SoilData(
          title: soilJson['name']?.toString() ?? 'Unknown Soil',
          soilType: _extractSoilType(soilJson['name']?.toString() ?? ''),
          soilImage: soilJson['image']?.toString(),
          soilIcon: 'assets/images/argile.png',
          crops: crops,
        );
      } else {
        print('Failed to fetch soil: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching soil: $e');
      return null;
    }
  }

  // Analysis History Operations - UPDATED to use enhanced backend
  static Future<List<PlantAnalysisResult>> getUserAnalysisHistory() async {
    try {
      // Use the enhanced backend service
      return await MainBackendService.getUserAnalysisHistory();
    } catch (e) {
      print('Error fetching analysis history: $e');
      return _getMockAnalysisHistory();
    }
  }

  static Future<Map<String, dynamic>> saveAnalysisResult(PlantAnalysisResult result) async {
    try {
      // The enhanced backend service automatically saves analyses
      // This method is kept for compatibility but could redirect to the enhanced service
      return {
        'success': true,
        'message': 'Analysis automatically saved by enhanced backend service',
        'data': result.toJson(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error saving analysis: $e',
      };
    }
  }

  // NEW: Get user analysis statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      return await MainBackendService.getUserAnalysisStatistics();
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching statistics: $e',
      };
    }
  }

  // Relationships
  static Future<List<PlantData>> getPlantsForSoil(int soilId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/soils/$soilId/plants/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (MainBackendService.accessToken != null)
            'Authorization': 'Bearer ${MainBackendService.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> plantsJson = responseData['plants'] ?? [];

        return plantsJson.map((plantJson) {
          final plant = plantJson as Map<String, dynamic>;
          return PlantData(
            plant['image']?.toString() ?? '',
            plant['name']?.toString() ?? 'Unknown Plant',
            'Healthy',
            'N/A',
            plant['description']?.toString() ?? 'No description available',
            'Suitable for this soil type',
          );
        }).toList();
      } else {
        print('Failed to fetch plants for soil: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching plants for soil: $e');
      return [];
    }
  }

  static Future<List<SoilData>> getSoilsForPlant(int plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/$plantId/soils/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (MainBackendService.accessToken != null)
            'Authorization': 'Bearer ${MainBackendService.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> soilsJson = responseData['soils'] ?? [];

        return soilsJson.map((soilJson) {
          final soil = soilJson as Map<String, dynamic>;
          return SoilData(
            title: soil['name']?.toString() ?? 'Unknown Soil',
            soilType: _extractSoilType(soil['name']?.toString() ?? ''),
            soilImage: soil['image']?.toString(),
            soilIcon: 'assets/images/argile.png',
            crops: [], // Will be populated if needed
          );
        }).toList();
      } else {
        print('Failed to fetch soils for plant: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching soils for plant: $e');
      return [];
    }
  }

  // Helper Methods
  static String _extractSoilType(String soilName) {
    final soilName_lower = soilName.toLowerCase();
    if (soilName_lower.contains('clay') || soilName_lower.contains('argile')) {
      return 'Clay';
    } else if (soilName_lower.contains('sand') || soilName_lower.contains('sable')) {
      return 'Sandy';
    } else if (soilName_lower.contains('loam') || soilName_lower.contains('limon')) {
      return 'Loam';
    } else if (soilName_lower.contains('peat') || soilName_lower.contains('tourbe')) {
      return 'Peat';
    } else {
      return 'Mixed';
    }
  }

  // Mock Data for Development/Offline Mode
  static List<PlantData> _getMockPlants() {
    return [
      PlantData(
        "https://images.unsplash.com/photo-1597848212624-a19eb35e2651?ixlib=rb-4.0.3",
        "Tomate Rouge",
        "Healthy",
        "N/A",
        "Plante de tomate productive, idéale pour les jardins familiaux.",
        "Arrosage régulier et exposition au soleil recommandés.",
      ),
      PlantData(
        "https://images.unsplash.com/photo-1586809206100-40e1d3953401?ixlib=rb-4.0.3",
        "Roses du Jardin",
        "Diseased",
        "Tache Noire",
        "Rosier affecté par la maladie des taches noires sur les feuilles.",
        "Traitement fongicide et amélioration de la ventilation nécessaires.",
      ),
      PlantData(
        "https://images.unsplash.com/photo-1600600552720-43a9d9a42f61?ixlib=rb-4.0.3",
        "Poivron Vert",
        "Attention",
        "Pucerons",
        "Poivron avec présence de pucerons sur les feuilles.",
        "Traitement insecticide biologique recommandé.",
      ),
    ];
  }

  static List<SoilData> _getMockSoils() {
    return [
      SoilData(
        title: "Terrain Principal",
        soilType: "Clay",
        soilImage: "https://images.unsplash.com/photo-1597048107223-c1543c71360c?q=80&w=2940",
        soilIcon: "assets/images/argile.png",
        crops: [
          CropData(icon: "assets/images/crops/mais.png", name: "Corn"),
          CropData(icon: "assets/images/crops/un-radis.png", name: "Radish"),
          CropData(icon: "assets/images/crops/chou-fleur.png", name: "Cauliflower"),
        ],
      ),
      SoilData(
        title: "Jardin Potager",
        soilType: "Loam",
        soilImage: "https://images.unsplash.com/photo-1542601900-7924d5763955?q=80&w=2940",
        soilIcon: "assets/images/argile.png",
        crops: [
          CropData(icon: "assets/images/crops/salade.png", name: "Lettuce"),
          CropData(icon: "assets/images/crops/oignon.png", name: "Onion"),
        ],
      ),
    ];
  }

  static List<PlantAnalysisResult> _getMockAnalysisHistory() {
    return [
      PlantAnalysisResult(
        className: "Tomato___healthy",
        status: "✅ Plante saine",
        species: "Tomate",
        disease: "Sain",
        imagePath: "/mock/path/tomato1.jpg",
        analyzedAt: DateTime.now().subtract(const Duration(days: 1)),
        isHealthy: true,
        confidence: 0.92,
      ),
      PlantAnalysisResult(
        className: "Pepper___bell____Bacterial_spot",
        status: "❌ Plante malade",
        species: "Poivron",
        disease: "Tache bactérienne",
        imagePath: "/mock/path/pepper1.jpg",
        analyzedAt: DateTime.now().subtract(const Duration(days: 3)),
        isHealthy: false,
        confidence: 0.87,
      ),
    ];
  }

  // Connection check
  static Future<bool> checkConnection() async {
    return await MainBackendService.checkMainBackendConnection();
  }
}