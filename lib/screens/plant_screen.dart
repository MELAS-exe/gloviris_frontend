import 'package:flutter/material.dart';
import 'package:gloviris_app/components/phone_camera_card.dart';
import '../components/device_connection_card.dart';
import '../components/plant_analysis_card.dart';
import '../components/soil_analysis_card.dart';
import '../components/search_bar.dart';
import '../models/plant_data.dart'; // Import PlantData
import '../theme/app_theme.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  final List<PlantData> plantDataList = [
    PlantData(
      "https://images.unsplash.com/photo-1597848212624-a19eb35e2651?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dG9tYXRvJTIwcGxhbnR8ZW58MHx8MHx8fDA%3D&w=1000&q=80",
      "Tomato Plant 1",
      "Healthy",
      "N/A",
      "No disease detected.",
      "Maintain regular watering and fertilization.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1586809206100-40e1d3953401?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8cm9zZSUyMGJ1c2h8ZW58MHx8MHx8fDA%3D&w=1000&q=80",
      "Rose Bush A",
      "Diseased",
      "Black Spot",
      "Fungal disease causing black spots on leaves, leading to yellowing and defoliation.",
      "Remove affected leaves, ensure good air circulation, and apply fungicide if necessary.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1600600552720-43a9d9a42f61?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fHBlcHBlciUyMHBsYW50fGVufDB8fDB8fHww&w=1000&q=80",
      "Pepper Plant X",
      "Attention",
      "Aphids",
      "Small insects feeding on plant sap, causing stunted growth and yellowing leaves.",
      "Spray with insecticidal soap or introduce beneficial insects like ladybugs.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1542464408-5f0c0d165f12?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Y3VjdW1iZXIlMjB2aW5lfGVufDB8fDB8fHww&w=1000&q=80",
      "Cucumber Vine",
      "Healthy",
      "N/A",
      "Vigorous growth and good fruit production.",
      "Provide adequate support and consistent watering.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1620005706248-26743907a974?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmFzaWwlMjBoZXJifGVufDB8fDB8fHww&w=1000&q=80",
      "Basil Herb",
      "Diseased",
      "Powdery Mildew",
      "Fungal disease appearing as white powdery spots on leaves and stems.",
      "Improve air circulation, avoid overhead watering, and apply a fungicide if severe.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1593005510325-633b09e102a3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8c3RyYXdiZXJyeSUyMHBhdGNofGVufDB8fDB8fHww&w=1000&q=80",
      "Strawberry Patch",
      "Attention",
      "Slugs",
      "Pests that chew holes in leaves and fruit, especially in damp conditions.",
      "Use slug traps, handpick them, or apply organic slug bait.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1560008354-a0951a5d2e3b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8c3VuZmxvd2VyJTIwZ2lhbnR8ZW58MHx8MHx8fDA%3D&w=1000&q=80",
      "Sunflower Giant",
      "Healthy",
      "N/A",
      "Tall stalk with a large, vibrant flower head.",
      "Ensure full sun exposure and well-drained soil.",
    ),
    PlantData(
      "https://images.unsplash.com/photo-1596199050303-3a453702a0b1?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8enVjY2hpbmklMjBwbGFudHxlbnwwfHwwfHx8MA%3D%3D&w=1000&q=80",
      "Zucchini Plant",
      "Healthy",
      "N/A",
      "Producing abundant fruit.",
      "Regular harvesting encourages more fruit production.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              // Scrollable soil analysis section
              Container(
                height: MediaQuery.of(context).size.height / 1.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildScrollableSoilAnalysisSection(),
                ),
              ),
            ],
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
            child: Image.asset("assets/images/logo.png")),
        const SizedBox(width: 10),
        Text(
          'GlovIris',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildScrollableSoilAnalysisSection() {
    return Card(
      child: Column(
        children: [
          // Fixed header within the card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plants scanned',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
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
          // Scrollable list of soil cards
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: plantDataList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return PlantAnalysisCard(plantData: plantDataList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
