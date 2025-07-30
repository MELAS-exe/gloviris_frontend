// lib/screens/plant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gloviris_app/components/phone_camera_card.dart';
import '../components/plant_analysis_card.dart';
import '../components/search_bar.dart';
import '../models/plant_data.dart';
import '../theme/app_theme.dart';
import '../view_models/AuthProvider.dart';
import '../view_models/PlantAnalysisProvider.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, healthy, diseased

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final plantProvider = Provider.of<PlantAnalysisProvider>(context, listen: false);
    await Future.wait([
      plantProvider.loadAnalysisHistory(),
      plantProvider.loadAllPlants(),
    ]);
  }

  Future<void> _refreshData() async {
    final plantProvider = Provider.of<PlantAnalysisProvider>(context, listen: false);
    await plantProvider.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<PlantAnalysisProvider, AuthProvider>(
          builder: (context, plantProvider, authProvider, child) {
            return RefreshIndicator(
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
                          _buildHeader(authProvider.isAuthenticated),
                          const SizedBox(height: 40),
                          const PhoneCameraCard(),
                          const SizedBox(height: 40),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    // Scrollable plant analysis section
                    Container(
                      height: MediaQuery.of(context).size.height / 1.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildScrollablePlantAnalysisSection(plantProvider),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAuthenticated) {
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      color: isAuthenticated ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAuthenticated ? 'IA & Base connectées' : 'Mode hors ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAuthenticated ? Colors.green : Colors.orange,
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

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Rechercher des plantes ou analyses...',
        hintStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppTheme.textSecondary,
          size: 30,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
    );
  }

  Widget _buildScrollablePlantAnalysisSection(PlantAnalysisProvider plantProvider) {
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (plantProvider.analysisHistory.isNotEmpty)
                      Text(
                        '${plantProvider.analysisHistory.length} analyses',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Filter',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showFilterDialog(plantProvider),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _selectedFilter != 'all'
                              ? AppTheme.primaryYellow.withOpacity(0.3)
                              : AppTheme.badgeBackground,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          size: 15,
                          color: _selectedFilter != 'all'
                              ? AppTheme.primaryYellow
                              : AppTheme.textSecondary,
                        ),
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
            child: _buildContent(plantProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PlantAnalysisProvider plantProvider) {
    if (plantProvider.isLoading) {
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

    if (plantProvider.error != null) {
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
                plantProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  plantProvider.clearError();
                  _refreshData();
                },
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

    // Get filtered data
    final filteredData = _getFilteredPlantData(plantProvider);

    if (filteredData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isEmpty && _selectedFilter == 'all'
                    ? Icons.eco
                    : Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyStateSubtitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _getEmptyStateAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_getEmptyStateIcon()),
                label: Text(_getEmptyStateButtonText()),
              ),
            ],
          ),
        ),
      );
    }

    // Display plant cards
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredData.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return PlantAnalysisCard(plantData: filteredData[index]);
      },
    );
  }

  List<dynamic> _getFilteredPlantData(PlantAnalysisProvider plantProvider) {
    // Combine analysis history and all plants
    List<dynamic> combinedData = [];

    // Add analysis history (convert to PlantData for compatibility)
    final analysisHistory = plantProvider.analysisHistory.map((analysis) {
      return PlantData(
        analysis.imagePath,
        analysis.species,
        analysis.isHealthy ? "Healthy" : "Diseased",
        analysis.disease,
        'Analyse du ${analysis.analyzedAt.day}/${analysis.analyzedAt.month}/${analysis.analyzedAt.year}',
        analysis.recommendations.join('\n• '),
      );
    }).toList();

    combinedData.addAll(analysisHistory);
    combinedData.addAll(plantProvider.allPlants);

    // Apply filters
    if (_selectedFilter == 'healthy') {
      combinedData = combinedData.where((item) {
        if (item is PlantData) {
          return item.healthStatus.toLowerCase() == 'healthy';
        }
        return false;
      }).toList();
    } else if (_selectedFilter == 'diseased') {
      combinedData = combinedData.where((item) {
        if (item is PlantData) {
          return item.healthStatus.toLowerCase() != 'healthy';
        }
        return false;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      combinedData = combinedData.where((item) {
        if (item is PlantData) {
          return item.plantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.diseaseName.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        return false;
      }).toList();
    }

    return combinedData;
  }

  String _getEmptyStateTitle() {
    if (_searchQuery.isNotEmpty) return 'Aucun résultat trouvé';
    if (_selectedFilter == 'healthy') return 'Aucune plante saine';
    if (_selectedFilter == 'diseased') return 'Aucune plante malade';
    return 'Aucune plante analysée';
  }

  String _getEmptyStateSubtitle() {
    if (_searchQuery.isNotEmpty) return 'Essayez avec d\'autres mots-clés.';
    if (_selectedFilter != 'all') return 'Changez le filtre pour voir plus de résultats.';
    return 'Utilisez l\'appareil photo pour analyser vos plantes et détecter les maladies.';
  }

  IconData _getEmptyStateIcon() {
    if (_searchQuery.isNotEmpty || _selectedFilter != 'all') return Icons.clear;
    return Icons.camera_alt;
  }

  String _getEmptyStateButtonText() {
    if (_searchQuery.isNotEmpty) return 'Effacer recherche';
    if (_selectedFilter != 'all') return 'Effacer filtre';
    return 'Analyser une plante';
  }

  VoidCallback _getEmptyStateAction() {
    return () {
      if (_searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = '';
        });
      } else if (_selectedFilter != 'all') {
        setState(() {
          _selectedFilter = 'all';
        });
      } else {
        // Trigger camera - scroll to top to show camera card
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
        );
      }
    };
  }

  void _showFilterDialog(PlantAnalysisProvider plantProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Filtrer les analyses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('all', 'Toutes les plantes', Icons.eco),
              _buildFilterOption('healthy', 'Plantes saines', Icons.check_circle, Colors.green),
              _buildFilterOption('diseased', 'Plantes malades', Icons.warning, Colors.red),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fermer',
                style: TextStyle(color: AppTheme.primaryYellow),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String title, IconData icon, [Color? color]) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textSecondary),
      title: Text(title),
      trailing: _selectedFilter == value
          ? const Icon(Icons.check, color: AppTheme.primaryGreen)
          : null,
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.of(context).pop();
      },
    );
  }
}