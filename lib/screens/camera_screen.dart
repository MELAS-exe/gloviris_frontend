// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import '../services/api_service.dart';
// import '../widgets/loading_overlay.dart';
//
// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});
//
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   bool _isInitialized = false;
//   bool _isLoading = false;
//   String? _capturedImagePath;
//   bool _showPreview = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras!.isNotEmpty) {
//         _controller = CameraController(
//           _cameras![0],
//           ResolutionPreset.high,
//           enableAudio: false,
//         );
//         await _controller!.initialize();
//         if (mounted) {
//           setState(() {
//             _isInitialized = true;
//           });
//         }
//       }
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }
//
//   Future<void> _takePicture() async {
//     if (_controller == null || !_controller!.value.isInitialized) return;
//
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final Directory appDir = await getApplicationDocumentsDirectory();
//       final String fileName = 'soil_sample_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final String filePath = path.join(appDir.path, fileName);
//
//       final XFile picture = await _controller!.takePicture();
//       await picture.saveTo(filePath);
//
//       setState(() {
//         _capturedImagePath = filePath;
//         _showPreview = true;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showErrorDialog('Failed to capture image: $e');
//     }
//   }
//
//   Future<void> _sendToBackend() async {
//     if (_capturedImagePath == null) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final result = await ApiService.analyzeSoilImage(_capturedImagePath!);
//
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//
//         // Show success dialog with analysis results
//         _showAnalysisResults(result);
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showErrorDialog('Failed to analyze soil: $e');
//     }
//   }
//
//   void _showAnalysisResults(Map<String, dynamic> result) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: const Text(
//             'Analysis Complete',
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Colors.black,
//             ),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Soil Type: ${result['soilType'] ?? 'Unknown'}'),
//               const SizedBox(height: 8),
//               Text('pH Level: ${result['phLevel'] ?? 'N/A'}'),
//               const SizedBox(height: 8),
//               Text('Moisture: ${result['moisture'] ?? 'N/A'}'),
//               const SizedBox(height: 8),
//               Text('Nutrients: ${result['nutrients'] ?? 'N/A'}'),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Navigator.of(context).pop(); // Return to main screen
//               },
//               child: const Text(
//                 'Done',
//                 style: TextStyle(
//                   color: Colors.orange,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: const Text(
//             'Error',
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Colors.red,
//             ),
//           ),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text(
//                 'OK',
//                 style: TextStyle(
//                   color: Colors.orange,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _retakePicture() {
//     setState(() {
//       _showPreview = false;
//       _capturedImagePath = null;
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Camera preview or captured image
//           if (_showPreview && _capturedImagePath != null)
//             _buildImagePreview()
//           else if (_isInitialized && _controller != null)
//             _buildCameraPreview()
//           else
//             _buildLoadingView(),
//
//           // Top bar with back button
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: IconButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       icon: const Icon(
//                         Icons.arrow_back,
//                         color: Colors.white,
//                         size: 24,
//                       ),
//                     ),
//                   ),
//                   if (!_showPreview)
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.5),
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: IconButton(
//                         onPressed: _switchCamera,
//                         icon: const Icon(
//                           Icons.flip_camera_ios,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Bottom controls
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Container(
//                 height: 120,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.transparent,
//                       Colors.black.withOpacity(0.8),
//                     ],
//                   ),
//                 ),
//                 child: _showPreview ? _buildPreviewControls() : _buildCameraControls(),
//               ),
//             ),
//           ),
//
//           // Loading overlay
//           if (_isLoading) const LoadingOverlay(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCameraPreview() {
//     return SizedBox(
//       width: double.infinity,
//       height: double.infinity,
//       child: CameraPreview(_controller!),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     return SizedBox(
//       width: double.infinity,
//       height: double.infinity,
//       child: Image.file(
//         File(_capturedImagePath!),
//         fit: BoxFit.cover,
//       ),
//     );
//   }
//
//   Widget _buildLoadingView() {
//     return const Center(
//       child: CircularProgressIndicator(
//         color: Colors.orange,
//       ),
//     );
//   }
//
//   Widget _buildCameraControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         const SizedBox(width: 60), // Spacer
//
//         // Capture button
//         GestureDetector(
//           onTap: _takePicture,
//           child: Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: Colors.orange,
//                 width: 4,
//               ),
//             ),
//             child: const Icon(
//               Icons.camera_alt,
//               color: Colors.orange,
//               size: 40,
//             ),
//           ),
//         ),
//
//         const SizedBox(width: 60), // Spacer
//       ],
//     );
//   }
//
//   Widget _buildPreviewControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         // Retake button
//         ElevatedButton(
//           onPressed: _retakePicture,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.grey.shade800,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(25),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           ),
//           child: const Text(
//             'Retake',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//
//         // Analyze button
//         ElevatedButton(
//           onPressed: _sendToBackend,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFFFFB03B),
//             foregroundColor: Colors.black,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(25),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//           ),
//           child: const Text(
//             'Analyze Soil',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _switchCamera() async {
//     if (_cameras == null || _cameras!.length < 2) return;
//
//     final currentCameraIndex = _cameras!.indexOf(_controller!.description);
//     final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;
//
//     await _controller!.dispose();
//     _controller = CameraController(
//       _cameras![newCameraIndex],
//       ResolutionPreset.high,
//       enableAudio: false,
//     );
//
//     try {
//       await _controller!.initialize();
//       if (mounted) {
//         setState(() {});
//       }
//     } catch (e) {
//       print('Error switching camera: $e');
//     }
//   }
// }