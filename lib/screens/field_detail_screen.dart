// lib/screens/field_detail_screen.dart
// Updated to fetch and display data from database

import 'package:flutter/material.dart';
import '../models/soil_data.dart';
import '../models/plant_data.dart';
import '../services/CrudService.dart';
import '../theme/app_theme.dart';

class FieldDetailScreen extends StatefulWidget {
  final SoilData soilData;

  const FieldDetailScreen({
    super.key,
    required this.soilData,
  });

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  List<PlantData> compatiblePlants = [];
  bool isLoadingPlants = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, dynamic> soilAnalysisData = {};

  @override
  void initState() {
    super.initState();
    _loadCompatiblePlants();
    _generateSoilAnalysisData();
  }

  void _generateSoilAnalysisData() {
    // Generate realistic soil analysis data based on soil type
    final soilType = widget.soilData.soilType.toLowerCase();

    if (soilType.contains('clay')) {
      soilAnalysisData = {
        'pH': '6.8',
        'moisture': '72%',
        'quality': '8.2/10',
        'nitrogen': 0.78,
        'phosphorus': 0.65,
        'potassium': 0.82,
        'organicMatter': 0.75,
        'drainage': 'Modéré',
        'temperature': '19°C',
        'texture': 'Argile',
        'organicContent': 'Élevé',
      };
    } else if (soilType.contains('sandy')) {
      soilAnalysisData = {
        'pH': '7.2',
        'moisture': '45%',
        'quality': '7.5/10',
        'nitrogen': 0.45,
        'phosphorus': 0.55,
        'potassium': 0.60,
        'organicMatter': 0.40,
        'drainage': 'Excellent',
        'temperature': '22°C',
        'texture': 'Sableux',
        'organicContent': 'Moyen',
      };
    } else if (soilType.contains('loam')) {
      soilAnalysisData = {
        'pH': '6.9',
        'moisture': '62%',
        'quality': '9.1/10',
        'nitrogen': 0.85,
        'phosphorus': 0.80,
        'potassium': 0.88,
        'organicMatter': 0.82,
        'drainage': 'Bon',
        'temperature': '20°C',
        'texture': 'Limoneux',
        'organicContent': 'Très élevé',
      };
    } else {
      // Default values
      soilAnalysisData = {
        'pH': '7.0',
        'moisture': '58%',
        'quality': '8.0/10',
        'nitrogen': 0.70,
        'phosphorus': 0.65,
        'potassium': 0.75,
        'organicMatter': 0.68,
        'drainage': 'Bon',
        'temperature': '21°C',
        'texture': widget.soilData.soilType,
        'organicContent': 'Élevé',
      };
    }
  }

  Future<void> _loadCompatiblePlants() async {
    setState(() {
      isLoadingPlants = true;
      hasError = false;
    });

    try {
      // Try to get plants compatible with this soil from database
      // Note: You'll need to implement getSoilId() method or pass soil ID
      final plants = await CrudService.getAllPlants(); // Fallback to all plants

      // Filter plants that are compatible with this soil type
      final filtered = plants.where((plant) {
        return _isPlantCompatibleWithSoil(plant, widget.soilData.soilType);
      }).toList();

      setState(() {
        compatiblePlants = filtered.isNotEmpty ? filtered : plants.take(6).toList();
        isLoadingPlants = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPlants = false;
        hasError = true;
        errorMessage = e.toString();
        // Use existing crops from soilData as fallback
        compatiblePlants = widget.soilData.crops.map((crop) {
          return PlantData(
            crop.icon,
            crop.name,
            'Compatible',
            'N/A',
            'Plante compatible avec ce type de sol.',
            'Cultivation recommandée pour ce sol.',
          );
        }).toList();
      });
    }
  }

  bool _isPlantCompatibleWithSoil(PlantData plant, String soilType) {
    final plantName = plant.plantName.toLowerCase();
    final soilTypeLower = soilType.toLowerCase();

    // Clay soil compatibility
    if (soilTypeLower.contains('clay')) {
      return plantName.contains('tomate') ||
          plantName.contains('tomato') ||
          plantName.contains('choux') ||
          plantName.contains('cabbage') ||
          plantName.contains('rose');
    }

    // Sandy soil compatibility
    if (soilTypeLower.contains('sandy')) {
      return plantName.contains('carotte') ||
          plantName.contains('carrot') ||
          plantName.contains('radis') ||
          plantName.contains('radish') ||
          plantName.contains('herbe') ||
          plantName.contains('herb');
    }

    // Loam soil - most compatible
    if (soilTypeLower.contains('loam')) {
      return true; // Loam is good for most plants
    }

    return true; // Default to compatible
  }

  String getCropImagePath(String cropName) {
    final Map<String, String> cropImageMap = {
      "garlic": "assets/images/crops/ail.png",
      "dill": "assets/images/crops/aneth.png",
      "cauliflower": "assets/images/crops/chou-fleur.png",
      "cabbage": "assets/images/crops/choux.png",
      "shallot": "assets/images/crops/echalote.png",
      "edamame": "assets/images/crops/edamame.png",
      "red bean": "assets/images/crops/haricot-rouge.png",
      "green beans": "assets/images/crops/haricots-verts.png",
      "alfalfa": "assets/images/crops/luzerne.png",
      "corn": "assets/images/crops/mais.png",
      "onion": "assets/images/crops/oignon.png",
      "green pepper": "assets/images/crops/poivre-vert.png",
      "lettuce": "assets/images/crops/salade.png",
      "radish": "assets/images/crops/un-radis.png",
      "yucca": "assets/images/crops/yucca.png",
      "tomate": "assets/images/crops/mais.png", // Fallback
      "tomato": "assets/images/crops/mais.png", // Fallback
    };

    final key = cropName.toLowerCase().trim();
    return cropImageMap[key] ?? "assets/images/crops/mais.png";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldImageCard(),
                    const SizedBox(height: 30),
                    _buildSoilAnalysisSection(),
                    const SizedBox(height: 30),
                    _buildNutrientLevelsSection(),
                    const SizedBox(height: 30),
                    _buildRecommendedCropsSection(),
                    const SizedBox(height: 30),
                    _buildSoilPropertiesSection(),
                    const SizedBox(height: 30),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.soilData.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.terrain,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Analyse détaillée du sol',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                _showShareDialog(context);
              },
              icon: const Icon(
                Icons.share,
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldImageCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.soilData.soilImage != null && widget.soilData.soilImage!.isNotEmpty
                ? Image.network(
              widget.soilData.soilImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.3),
                        AppTheme.primaryYellow.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.terrain,
                    size: 100,
                    color: AppTheme.primaryGreen,
                  ),
                );
              },
            )
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.3),
                    AppTheme.primaryYellow.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.terrain,
                size: 100,
                color: AppTheme.primaryGreen,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.soilData.title} - Sol ${widget.soilData.soilType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Analysé',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résultats d\'analyse du sol',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildAnalysisRow('Type de sol', widget.soilData.soilType, AppTheme.primaryGreen),
              const SizedBox(height: 15),
              _buildAnalysisRow('Niveau pH', soilAnalysisData['pH'], AppTheme.primaryYellow),
              const SizedBox(height: 15),
              _buildAnalysisRow('Humidité', soilAnalysisData['moisture'], Colors.blue),
              const SizedBox(height: 15),
              _buildAnalysisRow('Score qualité', soilAnalysisData['quality'], AppTheme.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientLevelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveaux de nutriments',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildNutrientBar('Azote (N)', soilAnalysisData['nitrogen'], AppTheme.primaryGreen),
              const SizedBox(height: 20),
              _buildNutrientBar('Phosphore (P)', soilAnalysisData['phosphorus'], AppTheme.primaryYellow),
              const SizedBox(height: 20),
              _buildNutrientBar('Potassium (K)', soilAnalysisData['potassium'], Colors.orange),
              const SizedBox(height: 20),
              _buildNutrientBar('Matière organique', soilAnalysisData['organicMatter'], Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientBar(String nutrient, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nutrient,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.badgeBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedCropsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cultures recommandées',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (isLoadingPlants)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryYellow,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: isLoadingPlants
              ? const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryYellow,
            ),
          )
              : compatiblePlants.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco,
                  size: 32,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aucune culture recommandée disponible',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: compatiblePlants.length,
            itemBuilder: (context, index) {
              final plant = compatiblePlants[index];
              return Container(
                width: 100,
                margin: EdgeInsets.only(
                  right: index < compatiblePlants.length - 1 ? 15 : 0,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: plant.plantImage.startsWith('http')
                            ? Image.network(
                          plant.plantImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              getCropImagePath(plant.plantName),
                              fit: BoxFit.cover,
                            );
                          },
                        )
                            : Image.asset(
                          getCropImagePath(plant.plantName),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plant.plantName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSoilPropertiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Propriétés du sol',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildPropertyItem(
                icon: Icons.opacity,
                title: 'Drainage',
                value: soilAnalysisData['drainage'],
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              _buildPropertyItem(
                icon: Icons.thermostat,
                title: 'Température',
                value: soilAnalysisData['temperature'],
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              _buildPropertyItem(
                icon: Icons.grain,
                title: 'Texture',
                value: soilAnalysisData['texture'],
                color: Colors.brown,
              ),
              const SizedBox(height: 20),
              _buildPropertyItem(
                icon: Icons.eco,
                title: 'Contenu organique',
                value: soilAnalysisData['organicContent'],
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              _showAnalysisDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Nouvelle analyse du sol',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton(
            onPressed: () {
              _showPlantingGuideDialog();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Guide de plantation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showShareDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Partager l\'analyse',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          content: const Text(
            'Fonctionnalité de partage bientôt disponible !\n\nVous pourrez partager vos analyses de sol avec d\'autres agriculteurs.',
          ),
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

  void _showAnalysisDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.science, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Nouvelle analyse',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'Pour effectuer une nouvelle analyse de ce sol :\n\n'
                '• Utilisez le capteur de sol GlovIris\n'
                '• Connectez-le via Bluetooth\n'
                '• Placez le capteur dans le sol\n'
                '• Les résultats apparaîtront automatiquement\n\n'
                'Assurez-vous que le sol est à la bonne humidité pour des résultats optimaux.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Compris',
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

  void _showPlantingGuideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.menu_book, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Guide de plantation',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recommandations pour sol ${widget.soilData.soilType} :',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._getPlantingRecommendations().map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fermer',
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

  List<String> _getPlantingRecommendations() {
    final soilType = widget.soilData.soilType.toLowerCase();

    if (soilType.contains('clay')) {
      return [
        'Améliorez le drainage avec du compost ou du sable',
        'Plantez au printemps quand le sol est moins humide',
        'Évitez de marcher sur le sol humide',
        'Privilégiez les cultures qui tolèrent l\'humidité',
        'Ajoutez de la matière organique régulièrement',
      ];
    } else if (soilType.contains('sandy')) {
      return [
        'Arrosez plus fréquemment car le sol draine rapidement',
        'Ajoutez du compost pour retenir l\'humidité',
        'Fertilisez plus souvent car les nutriments s\'évacuent',
        'Plantez des cultures qui résistent à la sécheresse',
        'Paillez pour conserver l\'humidité',
      ];
    } else if (soilType.contains('loam')) {
      return [
        'Sol idéal pour la plupart des cultures',
        'Maintenez la structure avec du compost',
        'Arrosage modéré et régulier',
        'Rotation des cultures recommandée',
        'Surveillez le pH régulièrement',
      ];
    } else {
      return [
        'Testez régulièrement la composition du sol',
        'Adaptez l\'arrosage selon les besoins',
        'Ajoutez des amendements selon les analyses',
        'Consultez un expert pour des conseils spécifiques',
        'Observez la réaction des plantes',
      ];
    }
  }
}