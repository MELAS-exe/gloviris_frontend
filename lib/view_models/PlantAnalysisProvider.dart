// lib/providers/plant_analysis_provider.dart
import 'package:flutter/foundation.dart';
import '../models/plant_analysis_result.dart';
import '../models/plant_data.dart';
import '../services/plant_ai_service.dart';
import '../services/main_backend_service.dart';
import '../services/CrudService.dart';

class PlantAnalysisProvider with ChangeNotifier {
  List<PlantAnalysisResult> _analysisHistory = [];
  List<PlantData> _allPlants = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  PlantAnalysisResult? _currentAnalysis;
  Map<String, dynamic>? _userStatistics;

  // Getters
  List<PlantAnalysisResult> get analysisHistory => _analysisHistory;
  List<PlantData> get allPlants => _allPlants;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  PlantAnalysisResult? get currentAnalysis => _currentAnalysis;
  Map<String, dynamic>? get userStatistics => _userStatistics;

  // Load analysis history
  Future<void> loadAnalysisHistory() async {
    _setLoading(true);
    
    try {
      _analysisHistory = await CrudService.getUserAnalysisHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to load analysis history: $e';
      _analysisHistory = [];
    }
    
    _setLoading(false);
  }

  // Load all plants from database
  Future<void> loadAllPlants() async {
    _setLoading(true);
    
    try {
      _allPlants = await CrudService.getAllPlants();
      _error = null;
    } catch (e) {
      _error = 'Failed to load plants: $e';
      _allPlants = [];
    }
    
    _setLoading(false);
  }

  // Analyze plant image
  Future<PlantAnalysisResult?> analyzePlantImage(String imagePath) async {
    _setAnalyzing(true);
    _clearError();

    try {
      final result = await PlantApiService.analyzePlantImage(imagePath);

      if (result['success'] == true) {
        final analysisResult = PlantAnalysisResult.fromJson(
          result['data'] ?? result,
          imagePath,
        );

        _currentAnalysis = analysisResult;
        
        // Add to history if analysis was successful
        _analysisHistory.insert(0, analysisResult);
        
        // Update statistics
        await _updateUserStatistics();
        
        _error = null;
        _setAnalyzing(false);
        return analysisResult;
      } else {
        _error = result['error'] ?? 'Analysis failed';
        _setAnalyzing(false);
        return null;
      }
    } catch (e) {
      _error = 'Analysis error: $e';
      _setAnalyzing(false);
      return null;
    }
  }

  // Save analysis result manually (if needed)
  Future<bool> saveAnalysisResult(PlantAnalysisResult result) async {
    try {
      final saveResult = await CrudService.saveAnalysisResult(result);
      
      if (saveResult['success'] == true) {
        // Add to local history if not already present
        if (!_analysisHistory.any((analysis) => 
            analysis.imagePath == result.imagePath && 
            analysis.analyzedAt == result.analyzedAt)) {
          _analysisHistory.insert(0, result);
          notifyListeners();
        }
        
        await _updateUserStatistics();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = 'Failed to save analysis: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete analysis from history
  Future<bool> deleteAnalysis(PlantAnalysisResult analysis) async {
    try {
      // Remove from local list
      _analysisHistory.removeWhere((item) => 
          item.imagePath == analysis.imagePath && 
          item.analyzedAt == analysis.analyzedAt);
      
      notifyListeners();
      
      // Update statistics
      await _updateUserStatistics();
      
      return true;
    } catch (e) {
      _error = 'Failed to delete analysis: $e';
      notifyListeners();
      return false;
    }
  }

  // Get filtered analysis history
  List<PlantAnalysisResult> getFilteredHistory({
    bool? healthyOnly,
    String? speciesFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    var filtered = _analysisHistory.toList();

    if (healthyOnly != null) {
      filtered = filtered.where((analysis) => analysis.isHealthy == healthyOnly).toList();
    }

    if (speciesFilter != null && speciesFilter.isNotEmpty) {
      filtered = filtered.where((analysis) => 
          analysis.species.toLowerCase().contains(speciesFilter.toLowerCase())
      ).toList();
    }

    if (fromDate != null) {
      filtered = filtered.where((analysis) => 
          analysis.analyzedAt.isAfter(fromDate) || 
          analysis.analyzedAt.isAtSameMomentAs(fromDate)
      ).toList();
    }

    if (toDate != null) {
      filtered = filtered.where((analysis) => 
          analysis.analyzedAt.isBefore(toDate) || 
          analysis.analyzedAt.isAtSameMomentAs(toDate)
      ).toList();
    }

    return filtered;
  }

  // Get analysis statistics
  Map<String, dynamic> getAnalysisStatistics() {
    if (_analysisHistory.isEmpty) {
      return {
        'totalAnalyses': 0,
        'healthyPlants': 0,
        'diseasedPlants': 0,
        'healthPercentage': 0.0,
        'mostCommonSpecies': null,
        'recentAnalysisDate': null,
      };
    }

    final totalAnalyses = _analysisHistory.length;
    final healthyPlants = _analysisHistory.where((a) => a.isHealthy).length;
    final diseasedPlants = totalAnalyses - healthyPlants;
    final healthPercentage = (healthyPlants / totalAnalyses) * 100;

    // Find most common species
    final speciesCount = <String, int>{};
    for (final analysis in _analysisHistory) {
      speciesCount[analysis.species] = (speciesCount[analysis.species] ?? 0) + 1;
    }

    String? mostCommonSpecies;
    int maxCount = 0;
    for (final entry in speciesCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonSpecies = entry.key;
      }
    }

    return {
      'totalAnalyses': totalAnalyses,
      'healthyPlants': healthyPlants,
      'diseasedPlants': diseasedPlants,
      'healthPercentage': healthPercentage,
      'mostCommonSpecies': mostCommonSpecies,
      'recentAnalysisDate': _analysisHistory.first.analyzedAt,
    };
  }

  // Update user statistics from backend
  Future<void> _updateUserStatistics() async {
    try {
      if (MainBackendService.isAuthenticated) {
        final result = await MainBackendService.getUserAnalysisStatistics();
        if (result['success'] == true) {
          _userStatistics = result['data'];
        }
      }
    } catch (e) {
      print('Failed to update user statistics: $e');
    }
  }

  // Search plants
  List<PlantData> searchPlants(String query) {
    if (query.isEmpty) return _allPlants;
    
    return _allPlants.where((plant) => 
        plant.plantName.toLowerCase().contains(query.toLowerCase()) ||
        plant.diseaseName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadAnalysisHistory(),
      loadAllPlants(),
      _updateUserStatistics(),
    ]);
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
    _currentAnalysis = null;
    notifyListeners();
  }
}