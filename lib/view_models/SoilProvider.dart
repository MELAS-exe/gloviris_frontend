// lib/providers/soil_provider.dart
import 'package:flutter/foundation.dart';
import '../models/soil_data.dart';
import '../models/plant_data.dart';
import '../services/CrudService.dart';

class SoilProvider with ChangeNotifier {
  List<SoilData> _soilAnalyses = [];
  List<SoilData> _allSoils = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  SoilData? _currentSoilAnalysis;
  bool _isConnected = false;

  // Getters
  List<SoilData> get soilAnalyses => _soilAnalyses;
  List<SoilData> get allSoils => _allSoils;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  SoilData? get currentSoilAnalysis => _currentSoilAnalysis;
  bool get isConnected => _isConnected;

  // Load soil analyses
  Future<void> loadSoilAnalyses() async {
    _setLoading(true);
    
    try {
      _soilAnalyses = await CrudService.getAllSoils();
      _error = null;
    } catch (e) {
      _error = 'Failed to load soil analyses: $e';
      _soilAnalyses = [];
    }
    
    _setLoading(false);
  }

  // Load all soils from database
  Future<void> loadAllSoils() async {
    _setLoading(true);
    
    try {
      _allSoils = await CrudService.getAllSoils();
      _error = null;
    } catch (e) {
      _error = 'Failed to load soils: $e';
      _allSoils = [];
    }
    
    _setLoading(false);
  }

  // Check backend connection
  Future<void> checkConnection() async {
    try {
      _isConnected = await CrudService.checkConnection();
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  // Simulate soil analysis (for device connection)
  Future<SoilData?> analyzeSoilWithDevice(String deviceId) async {
    _setAnalyzing(true);
    _clearError();

    try {
      // Simulate device analysis - replace with actual device communication
      await Future.delayed(const Duration(seconds: 3));

      // Create mock analysis result
      final analysisResult = SoilData(
        title: "Analyse ${DateTime.now().day}/${DateTime.now().month}",
        soilType: _generateRandomSoilType(),
        soilImage: null,
        soilIcon: "assets/images/argile.png",
        crops: _generateRecommendedCrops(),
      );

      _currentSoilAnalysis = analysisResult;
      _soilAnalyses.insert(0, analysisResult);
      
      _error = null;
      _setAnalyzing(false);
      return analysisResult;
    } catch (e) {
      _error = 'Device analysis failed: $e';
      _setAnalyzing(false);
      return null;
    }
  }

  // Get soil by ID
  Future<SoilData?> getSoilById(int id) async {
    try {
      return await CrudService.getSoilById(id);
    } catch (e) {
      _error = 'Failed to get soil details: $e';
      notifyListeners();
      return null;
    }
  }

  // Get plants for specific soil
  Future<List<PlantData>> getPlantsForSoil(int soilId) async {
    try {
      return await CrudService.getPlantsForSoil(soilId);
    } catch (e) {
      _error = 'Failed to get compatible plants: $e';
      notifyListeners();
      return [];
    }
  }

  // Get soils for specific plant
  Future<List<SoilData>> getSoilsForPlant(int plantId) async {
    try {
      return await CrudService.getSoilsForPlant(plantId);
    } catch (e) {
      _error = 'Failed to get compatible soils: $e';
      notifyListeners();
      return [];
    }
  }

  // Search soils
  List<SoilData> searchSoils(String query) {
    if (query.isEmpty) return _allSoils;
    
    return _allSoils.where((soil) => 
        soil.title.toLowerCase().contains(query.toLowerCase()) ||
        soil.soilType.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Filter soils by type
  List<SoilData> filterSoilsByType(String soilType) {
    return _allSoils.where((soil) => 
        soil.soilType.toLowerCase() == soilType.toLowerCase()
    ).toList();
  }

  // Get soil statistics
  Map<String, dynamic> getSoilStatistics() {
    if (_soilAnalyses.isEmpty) {
      return {
        'totalAnalyses': 0,
        'soilTypes': <String, int>{},
        'averageQuality': 0.0,
        'recommendedCropsCount': 0,
      };
    }

    final totalAnalyses = _soilAnalyses.length;
    final soilTypes = <String, int>{};
    int totalCrops = 0;

    for (final soil in _soilAnalyses) {
      soilTypes[soil.soilType] = (soilTypes[soil.soilType] ?? 0) + 1;
      totalCrops += soil.crops.length;
    }

    return {
      'totalAnalyses': totalAnalyses,
      'soilTypes': soilTypes,
      'averageQuality': 8.2, // Mock average quality
      'recommendedCropsCount': totalCrops,
    };
  }

  // Delete soil analysis
  Future<bool> deleteSoilAnalysis(SoilData soil) async {
    try {
      _soilAnalyses.removeWhere((item) => 
          item.title == soil.title && item.soilType == soil.soilType);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete soil analysis: $e';
      notifyListeners();
      return false;
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadSoilAnalyses(),
      loadAllSoils(),
      checkConnection(),
    ]);
  }

  // Helper methods for mock data generation
  String _generateRandomSoilType() {
    final types = ['Clay', 'Sandy', 'Loam', 'Peat', 'Chalky'];
    types.shuffle();
    return types.first;
  }

  List<CropData> _generateRecommendedCrops() {
    final crops = [
      CropData(icon: "assets/images/crops/mais.png", name: "Corn"),
      CropData(icon: "assets/images/crops/un-radis.png", name: "Radish"),
      CropData(icon: "assets/images/crops/salade.png", name: "Lettuce"),
      CropData(icon: "assets/images/crops/oignon.png", name: "Onion"),
      CropData(icon: "assets/images/crops/chou-fleur.png", name: "Cauliflower"),
    ];
    
    crops.shuffle();
    return crops.take(3).toList();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setAnalyzing(bool analyzing) {
    _isAnalyzing = analyzing;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Clear current analysis
  void clearCurrentAnalysis() {
    _currentSoilAnalysis = null;
    notifyListeners();
  }
}