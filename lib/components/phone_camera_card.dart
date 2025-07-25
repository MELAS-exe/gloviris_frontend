import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/PlantCameraScreen.dart';
import '../screens/PlantResultScreen.dart';
import '../services/plant_ai_service.dart';
import '../models/plant_analysis_result.dart';
import '../theme/app_theme.dart';

class PhoneCameraCard extends StatelessWidget {
  const PhoneCameraCard({super.key});

  Future<void> _openCamera(BuildContext context) async {
    // Navigate to the dedicated camera screen for better UX
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlantCameraScreen(),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Analyse en cours...'),
                ],
              ),
            );
          },
        );

        try {
          // Analyze the selected image
          final result = await PlantApiService.analyzePlantImage(image.path);

          // Close loading dialog
          Navigator.of(context).pop();

          if (result['success'] == true) {
            // Success - navigate to results screen
            final analysisResult = PlantAnalysisResult.fromJson(
                result['data'],
                image.path
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlantResultScreen(
                  analysisResult: analysisResult,
                ),
              ),
            );
          } else {
            // Handle API failure
            _showErrorDialog(context, 'Échec de l\'analyse. Vérifiez votre connexion.');
          }
        } catch (e) {
          // Close loading dialog
          Navigator.of(context).pop();
          _showErrorDialog(context, 'Erreur lors de l\'analyse: $e');
        }
      }
    } catch (e) {
      _showErrorDialog(context, 'Erreur lors de la sélection d\'image: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Erreur',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Analyser une plante',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Caméra',
                    onTap: () {
                      Navigator.pop(context);
                      _openCamera(context);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.primaryYellow.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppTheme.primaryYellow,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withOpacity(0.8),
            AppTheme.primaryRed.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 20),
              height: 200,
              child: Image.asset("assets/images/phone.png"),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Analysez vos plantes avec l\'IA pour détecter les maladies',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showImageSourceDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.textPrimary,
                    minimumSize: const Size(120, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Analyser',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}