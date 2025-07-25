// lib/screens/plant_screen.dart
// Updated to fetch data from database

import 'package:flutter/material.dart';
import 'package:gloviris_app/components/phone_camera_card.dart';
import '../components/plant_analysis_card.dart';
import '../components/search_bar.dart';
import '../models/plant_data.dart';
import '../services/CrudService.dart';
import '../theme/app_theme.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  List<PlantData> plantDataList = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadPlantData();
  }

  Future<void> _loadPlantData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Check connection status
      isConnected = await CrudService.checkConnection();

      // Try to fetch analysis history first (user's personal analyses)
      List<PlantData> userAnalyses = [];
      try {
        final analysisHistory = await CrudService.getUserAnalysisHistory();
        userAnalyses = analysisHistory.map((analysis) {
          return PlantData(
            analysis.imagePath,
            analysis.species,
            analysis.isHealthy ? "Healthy" : "Diseased",
            analysis.disease,
            _getStatusDescription(analysis.status),
            analysis.recommendations.join('\n• '),
          );
        }).toList();
      } catch (e) {
        print('Could not fetch user analysis history: $e');
      }

      // Fetch general plant database
      final plants = await CrudService.getAllPlants();

      // Combine user analyses with general plant database
      // Put user analyses first for better UX
      final combinedList = <PlantData>[];
      combinedList.addAll(userAnalyses);
      combinedList.addAll(plants);

      setState(() {
        plantDataList = combinedList;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  String _getStatusDescription(String status) {
    if (status.contains('✅')) {
      return 'Plante en excellent état de santé. Continuez les soins actuels.';
    } else if (status.contains('❌')) {
      return 'Problème détecté sur la plante. Intervention recommandée.';
    } else {
      return 'État de la plante à surveiller. Vérifiez régulièrement.';
    }
  }

  Future<void> _refreshData() async {
    await _loadPlantData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.primaryYellow,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Fixed header section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      const PhoneCameraCard(),
                      const SizedBox(height: 40),
                      const CustomSearchBar(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Scrollable plant analysis section
                Container(
                  height: MediaQuery
                      .of(context)
                      .size
                      .height / 1.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildScrollablePlantAnalysisSection(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          child: Image.asset("assets/images/logo.png"),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GlovIris',
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'IA & Base connectées' : 'Mode hors ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollablePlantAnalysisSection() {
    return Card(
      child: Column(
        children: [
          // Fixed header within the card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plantes analysées',
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (!isConnected)
                      const Text(
                        'Données locales disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Filter',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.badgeBackground,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryYellow,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des analyses...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: AppTheme.textPrimary,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (plantDataList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune plante analysée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Utilisez l\'appareil photo pour analyser vos plantes et détecter les maladies.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Scroll back to camera card or trigger camera
                  setState(() {
                    // Refresh to show any new analyses
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Analyser une plante'),
              ),
            ],
          ),
        ),
      );
    }

    // Display plant cards with section headers
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _getTotalItemCount(),
      itemBuilder: (context, index) {
        return _buildListItem(index);
      },
    );
  }

  int _getTotalItemCount() {
    int count = plantDataList.length;

    // Add section headers
    if (plantDataList.any((plant) => _isUserAnalysis(plant))) {
      count += 1; // Header for "Mes analyses"
    }
    if (plantDataList.any((plant) => !_isUserAnalysis(plant))) {
      count += 1; // Header for "Base de données"
    }

    return count;
  }

  Widget _buildListItem(int index) {
    int currentIndex = 0;

    // Check if we need "Mes analyses" header
    bool hasUserAnalyses = plantDataList.any((plant) => _isUserAnalysis(plant));

    // Count user analyses
    int userAnalysesCount = plantDataList
        .where((plant) => _isUserAnalysis(plant))
        .length;

    // Show user analyses
    if (index < currentIndex + userAnalysesCount) {
      final userAnalyses = plantDataList.where((plant) =>
          _isUserAnalysis(plant)).toList();
      final plantIndex = index - currentIndex;
      return Column(
        children: [
          PlantAnalysisCard(plantData: userAnalyses[plantIndex]),
          if (plantIndex < userAnalyses.length - 1) const SizedBox(height: 20),
        ],
      );
    }
    currentIndex += userAnalysesCount;

    // Check if we need "Base de données" header
    bool hasDbPlants = plantDataList.any((plant) => !_isUserAnalysis(plant));
    if (hasDbPlants && index == currentIndex) {
      currentIndex++;
      return Column(
        children: [
          const SizedBox(height: 20),
        ],
      );
    }

    // Show database plants
    final dbPlants = plantDataList
        .where((plant) => !_isUserAnalysis(plant))
        .toList();
    final dbIndex = index - currentIndex;

    if (dbIndex < dbPlants.length) {
      return Column(
        children: [
          PlantAnalysisCard(plantData: dbPlants[dbIndex]),
          if (dbIndex < dbPlants.length - 1) const SizedBox(height: 20),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  bool _isUserAnalysis(PlantData plant) {
    // Check if this is a user's analysis vs database plant
    // User analyses typically have image paths that include timestamps or are local paths
    return plant.plantImage.contains('/') &&
        (plant.plantImage.contains('plant_sample_') ||
            plant.plantImage.contains('/mock/') ||
            plant.plantImage.startsWith('/'));
  }
}