// lib/screens/soil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/device_connection_card.dart';
import '../components/soil_analysis_card.dart';
import '../components/search_bar.dart';
import '../theme/app_theme.dart';
import '../view_models/SoilProvider.dart';

class SoilScreen extends StatefulWidget {
  const SoilScreen({super.key});

  @override
  State<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends State<SoilScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final soilProvider = Provider.of<SoilProvider>(context, listen: false);
    await soilProvider.loadSoilAnalyses();
  }

  Future<void> _refreshData() async {
    final soilProvider = Provider.of<SoilProvider>(context, listen: false);
    await soilProvider.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<SoilProvider>(
          builder: (context, soilProvider, child) {
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
                          _buildHeader(soilProvider.isConnected),
                          const SizedBox(height: 40),
                          _buildDeviceConnectionCard(soilProvider),
                          const SizedBox(height: 40),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    // Scrollable soil analysis section
                    Container(
                      height: MediaQuery.of(context).size.height / 1.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildScrollableSoilAnalysisSection(soilProvider),
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

  Widget _buildHeader(bool isConnected) {
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
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'Base de données connectée' : 'Mode hors ligne',
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

  Widget _buildDeviceConnectionCard(SoilProvider soilProvider) {
    return GestureDetector(
      onTap: () => _showDeviceConnectionDialog(soilProvider),
      child: const DeviceConnectionCard(),
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
        hintText: 'Rechercher des analyses de sol...',
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

  Widget _buildScrollableSoilAnalysisSection(SoilProvider soilProvider) {
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
                      'Sols analysés',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (!soilProvider.isConnected)
                      const Text(
                        'Données locales',
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showFilterDialog(),
                      child: Container(
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Content area
          Expanded(
            child: _buildContent(soilProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SoilProvider soilProvider) {
    if (soilProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryYellow,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des données...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (soilProvider.error != null) {
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
                soilProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  soilProvider.clearError();
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

    final filteredSoils = _searchQuery.isEmpty
        ? soilProvider.soilAnalyses
        : soilProvider.searchSoils(_searchQuery);

    if (filteredSoils.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.terrain : Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'Aucun sol analysé' : 'Aucun résultat trouvé',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? 'Commencez par analyser votre sol avec l\'appareil de mesure.'
                    : 'Essayez avec d\'autres mots-clés.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _searchQuery.isEmpty
                    ? () => _showDeviceConnectionDialog(soilProvider)
                    : () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_searchQuery.isEmpty ? Icons.science : Icons.clear),
                label: Text(_searchQuery.isEmpty ? 'Analyser le sol' : 'Effacer recherche'),
              ),
            ],
          ),
        ),
      );
    }

    // Display soil cards
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredSoils.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return SoilAnalysisCard(soilData: filteredSoils[index]);
      },
    );
  }

  void _showDeviceConnectionDialog(SoilProvider soilProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.bluetooth, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Connexion appareil'),
            ],
          ),
          content: soilProvider.isAnalyzing
              ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryYellow),
              SizedBox(height: 16),
              Text('Analyse en cours...'),
            ],
          )
              : const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pour analyser votre sol :'),
              SizedBox(height: 12),
              Text('1. Allumez votre capteur GlovIris'),
              Text('2. Activez le Bluetooth'),
              Text('3. Placez le capteur dans le sol'),
              Text('4. Appuyez sur "Démarrer l\'analyse"'),
              SizedBox(height: 12),
              Text(
                'L\'analyse prendra environ 30 secondes.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            if (!soilProvider.isAnalyzing) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () => _startSoilAnalysis(soilProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: AppTheme.textPrimary,
                ),
                child: const Text('Démarrer l\'analyse'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _startSoilAnalysis(SoilProvider soilProvider) async {
    Navigator.of(context).pop(); // Close dialog

    // Show analysis dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryYellow),
            SizedBox(height: 16),
            Text('Analyse du sol en cours...'),
          ],
        ),
      ),
    );

    final result = await soilProvider.analyzeSoilWithDevice('device_001');

    if (mounted) {
      Navigator.of(context).pop(); // Close analysis dialog

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analyse terminée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${soilProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Filtrer les analyses'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fonctionnalité de filtrage bientôt disponible !'),
              SizedBox(height: 12),
              Text(
                'Vous pourrez filtrer par :\n'
                    '• Type de sol\n'
                    '• Date d\'analyse\n'
                    '• Qualité du sol\n'
                    '• Cultures recommandées',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: AppTheme.primaryYellow),
              ),
            ),
          ],
        );
      },
    );
  }
}