import 'package:flutter/material.dart';
import 'package:gloviris_app/models/plant_data.dart';
import '../models/soil_data.dart';
import '../screens/field_detail_screen.dart';
import '../theme/app_theme.dart';

class PlantAnalysisCard extends StatelessWidget {
  final PlantData plantData;

  const PlantAnalysisCard({
    super.key,
    required this.plantData,
  });

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
              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => FieldDetailScreen(soilData: soilData),
              //     ),
              //   );
              // },
              child: Text(
                plantData.plantName,
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
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.badgeBackground,
                    ),
                    child: Image.network(plantData.plantImage, fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                      // Placeholder image or icon when the network image fails to load
                      return const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: AppTheme.textSecondary,
                      ); // You can use any widget as a placeholder
                    }, loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHealthStatusBadge(),
                      const SizedBox(height: 10),
                      _buildDiseaseNameBadge(),
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
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => ,
                      //   ),
                      // );
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

  Color _getHealthStatusColor(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case "sick":
        return Colors.red;
      case "healthy":
        return Colors.green;
      case "diseased":
        return Colors.black;
      case "unknown":
      default:
        return Colors.yellow;
    }
  }

  Widget _buildHealthStatusBadge() {
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
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _getHealthStatusColor(plantData.healthStatus)),
          ),
          const SizedBox(width: 8),
          Text(
            plantData.healthStatus,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseNameBadge() {
    return Container(
        height: 30,
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.badgeBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(
          plantData.diseaseName,
          overflow: TextOverflow.ellipsis,
        )]));
  }
}
