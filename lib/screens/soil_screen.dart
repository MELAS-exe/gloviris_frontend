import 'package:flutter/material.dart';
import '../components/device_connection_card.dart';
import '../components/soil_analysis_card.dart';
import '../components/search_bar.dart';
import '../models/soil_data.dart';
import '../theme/app_theme.dart';

class SoilScreen extends StatefulWidget {
  const SoilScreen({super.key});

  @override
  State<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends State<SoilScreen> {
  final List<SoilData> soilCards = [
    SoilData(
      title: "Field Title",
      soilType: "Clay",
      soilImage: "https://images.unsplash.com/photo-1597048107223-c1543c71360c?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      soilIcon: "assets/images/clay_icon.png",
      crops: [
        CropData(icon: "assets/images/corn.png", name: "Corn"),
        CropData(icon: "assets/images/radish.png", name: "Radish"),
        CropData(icon: "assets/images/cauliflower.png", name: "Cauliflower"),
      ],
    ),
    SoilData(
      title: "Garden Plot A",
      soilType: "Loam",
      soilImage: "https://images.unsplash.com/photo-1542601900-7924d5763955?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      soilIcon: "assets/images/clay_icon.png",
      crops: [
        CropData(icon: "assets/images/corn.png", name: "Corn"),
        CropData(icon: "assets/images/radish.png", name: "Radish"),
      ],
    ),
    SoilData(
      title: "Greenhouse Bed 1",
      soilType: "Sandy",
      soilImage: "https://images.unsplash.com/photo-1601134799703-980b188c0397?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      soilIcon: "assets/images/clay_icon.png",
      crops: [
        CropData(icon: "assets/images/cauliflower.png", name: "Cauliflower"),
      ],
    ),
    SoilData(
      title: "Backyard Section",
      soilType: "Clay",
      soilImage: "https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      soilIcon: "assets/images/clay_icon.png",
      crops: [
        CropData(icon: "assets/images/corn.png", name: "Corn"),
        CropData(icon: "assets/images/radish.png", name: "Radish"),
        CropData(icon: "assets/images/cauliflower.png", name: "Cauliflower"),
      ],
    ),
    SoilData(
      title: "Front Yard Plot",
      soilType: "Loam",
      soilImage: "https://images.unsplash.com/photo-1509315811345-672d83ef2fbc?q=80&w=2864&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      soilIcon: "assets/images/clay_icon.png",
      crops: [
        CropData(icon: "assets/images/radish.png", name: "Radish"),
        CropData(icon: "assets/images/cauliflower.png", name: "Cauliflower"),
      ],
    ),
    SoilData(
      title: "Side Garden",
      soilType: "Sandy",
      soilImage: "https://images.unsplash.com/photo-1571503335010-4a8f79287612?q=80&w=2942&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      soilIcon: "assets/images/clay_icon.png",
      crops: [
        CropData(icon: "assets/images/corn.png", name: "Corn"),
      ],
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
                    const DeviceConnectionCard(),
                    const SizedBox(height: 40),
                    const CustomSearchBar(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Scrollable soil analysis section
              Container(
                height: MediaQuery.of(context).size.height/1.5,
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
          child: Image.asset("assets/images/logo.png")
        ),
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
                  'Soils analyzed',
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
              itemCount: soilCards.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return SoilAnalysisCard(soilData: soilCards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}