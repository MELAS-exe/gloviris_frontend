import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/soil_data.dart';
import '../screens/field_detail_screen.dart';
import '../theme/app_theme.dart';

class SoilAnalysisCard extends StatelessWidget {
  final SoilData soilData;

  const SoilAnalysisCard({
    super.key,
    required this.soilData,
  });

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
    };

    final key = cropName.toLowerCase().trim();

    return cropImageMap[key] ??
        "https://cdn-icons-png.flaticon.com/512/2909/2909865.png"; // fallback network image
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FieldDetailScreen(soilData: soilData),
                  ),
                );
              },
              child: Text(
                soilData.title,
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.badgeBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: soilData.soilImage != null &&
                            soilData.soilImage!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: soilData.soilImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(
                              Icons.terrain,
                              size: 40,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Icon(Icons.terrain,
                            size: 40, color: AppTheme.textSecondary),
                  ),


                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSoilTypeBadge(),
                      const SizedBox(height: 10),
                      _buildCropsBadge(),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FieldDetailScreen(soilData: soilData),
                        ),
                      );
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

  Widget _buildSoilTypeBadge() {
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
            child: Image.asset("assets/images/argile.png"),
          ),
          const SizedBox(width: 8),
          Text(
            soilData.soilType,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropsBadge() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.badgeBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: soilData.crops.take(3).map((crop) {
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
                width: 20,
                height: 20,
                child: Image.asset(getCropImagePath(crop.name))),
          );
        }).toList(),
      ),
    );
  }
}
