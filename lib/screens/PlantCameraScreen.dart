import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../components/loading_overlay.dart';
import '../models/plant_analysis_result.dart';
import '../services/plant_ai_service.dart';
import 'PlantResultScreen.dart';

class PlantCameraScreen extends StatefulWidget {
  const PlantCameraScreen({super.key});

  @override
  State<PlantCameraScreen> createState() => _PlantCameraScreenState();
}

class _PlantCameraScreenState extends State<PlantCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _capturedImagePath;
  bool _showPreview = false;
  bool _backendConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    final connected = await PlantApiService.checkBackendConnection();
    setState(() {
      _backendConnected = connected;
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorDialog('Erreur d\'initialisation de la caméra: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'plant_sample_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(appDir.path, fileName);

      final XFile picture = await _controller!.takePicture();
      await picture.saveTo(filePath);

      setState(() {
        _capturedImagePath = filePath;
        _showPreview = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Échec de la capture d\'image: $e');
    }
  }

  Future<void> _analyzePlant() async {
    if (_capturedImagePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await PlantApiService.analyzePlantImage(_capturedImagePath!);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Success - navigate to results screen
          final analysisResult = PlantAnalysisResult.fromJson(
            result['data'],
            _capturedImagePath!
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PlantResultScreen(
                analysisResult: analysisResult,
              ),
            ),
          );
        } else {
          // Handle API failure with mock data
          _showApiFailureDialog(result);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Échec de l\'analyse de la plante: $e');
    }
  }

  void _showApiFailureDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Connexion API échouée'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Impossible de se connecter au serveur d\'analyse.'),
              const SizedBox(height: 12),
              if (result['mock_data'] != null) ...[
                const Text('Données de test:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Espèce: ${result['mock_data']['espece']}'),
                Text('État: ${result['mock_data']['status']}'),
                Text('Maladie: ${result['mock_data']['maladie']}'),
              ],
              const SizedBox(height: 12),
              const Text(
                'Vérifiez que le serveur Django est démarré et accessible.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retakePicture();
              },
              child: const Text('Reprendre photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (result['mock_data'] != null) {
                  // Show mock data for development
                  final mockResult = PlantAnalysisResult.fromJson(
                    result['mock_data'],
                    _capturedImagePath!,
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantResultScreen(
                        analysisResult: mockResult,
                        isMockData: true,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Voir test'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
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

  void _retakePicture() {
    setState(() {
      _showPreview = false;
      _capturedImagePath = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or captured image
          if (_showPreview && _capturedImagePath != null)
            _buildImagePreview()
          else if (_isInitialized && _controller != null)
            _buildCameraPreview()
          else
            _buildLoadingView(),

          // Top bar with back button and connection status
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Connection status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _backendConnected ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _backendConnected ? 'API OK' : 'API Off',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_showPreview)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: _switchCamera,
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: _showPreview ? _buildPreviewControls() : _buildCameraControls(),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading) const LoadingOverlay(message: 'Analyse de la plante en cours...'),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.file(
        File(_capturedImagePath!),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.orange,
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 60), // Spacer

        // Capture button
        GestureDetector(
          onTap: _takePicture,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.orange,
                width: 4,
              ),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.orange,
              size: 40,
            ),
          ),
        ),

        const SizedBox(width: 60), // Spacer
      ],
    );
  }

  Widget _buildPreviewControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Retake button
        ElevatedButton(
          onPressed: _retakePicture,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Reprendre',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Analyze button
        ElevatedButton(
          onPressed: _analyzePlant,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB03B),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text(
            'Analyser la plante',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCameraIndex = _cameras!.indexOf(_controller!.description);
    final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

    await _controller!.dispose();
    _controller = CameraController(
      _cameras![newCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error switching camera: $e');
    }
  }
}