import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_ai_service.dart';
import '../main.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// // final user = FirebaseAuth.instance.currentUser;
// // print("User ID: ${user?.uid}");

class PlantAnalysisScreen extends StatefulWidget {
  final bool isFirebaseInitialized;
  const PlantAnalysisScreen({super.key, required this.isFirebaseInitialized});

  @override
  State<PlantAnalysisScreen> createState() => _PlantAnalysisScreenState();
}

class _PlantAnalysisScreenState extends State<PlantAnalysisScreen> {
  final FirebaseAIService _aiService = FirebaseAIService();
  Uint8List? _latestImage;
  String? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLatestUpload();
  }

  Future<void> _fetchLatestUpload() async {
    try {
      final uploadsRef = FirebaseDatabase.instance.ref('plantData/uploads');
      // final snapshot = await uploadsRef.orderByChild('ts').limitToLast(1).get();
      final snapshot = await uploadsRef.limitToLast(1).get();
      if (!snapshot.exists) {
        log('No snapshot found in uploads.');
      } else {
        log('Uploads children count: ${snapshot.children.length}');
        for (var child in snapshot.children) {
          log('Child key: ${child.key}');
        }
      }

      String? latestPath;
      String? latestTimestamp;
      snapshot.children.forEach((child) {
        latestPath = 'plantData/uploads/${child.key}';
        latestTimestamp = child.key;
      });

      if (latestPath != null && latestTimestamp != null) {
        final bytes = await _aiService.fetchAndDecodeImage(latestPath!);
        setState(() => _latestImage = bytes);
      }
    } catch (e) {
      log('Error fetching latest upload: $e');
    }
  }

  // Future<void> _runAnalysis() async {
  //   if (_latestImage == null) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('No image found.')));
  //     return;
  //   }

  //   setState(() => _loading = true);
  //   final result = await _aiService.analyzeImageWithGemini(_latestImage!);
  //   setState(() {
  //     _result = result;
  //     _loading = false;
  //   });
  // }

  Future<void> _runAnalysis() async {
    if (_latestImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No image found.')));
      return;
    }

    setState(() => _loading = true);

    // Run AI analysis
    final result = await _aiService.analyzeImageWithGemini(_latestImage!);

    // Save to Firebase (under /plantData/analysis)
    try {
      final uploadsRef = FirebaseDatabase.instance.ref('plantData/uploads');
      final snapshot = await uploadsRef.limitToLast(1).get();

      if (snapshot.exists) {
        final latestKey = snapshot.children.first.key;
        if (latestKey != null) {
          await _aiService.saveAnalysisResult(latestKey, result);
          log('AI analysis result saved to plantData/analysis/$latestKey');
        }
      }
    } catch (e) {
      log('Error saving AI result: $e');
    }

    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Health Analysis'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _latestImage != null
                ? Image.memory(_latestImage!)
                : const Text('No image available.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.science),
              onPressed: _loading ? null : _runAnalysis,
              label: Text(_loading ? 'Analyzing...' : 'Analyze with AI'),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Builder(
                builder: (context) {
                  final lower = _result!.toLowerCase();
                  Color? bgColor;
                  Color? textColor;

                  if (lower.contains('healthy') &&
                      !lower.contains('unhealthy')) {
                    // ✅ Healthy → green
                    bgColor = Colors.green[50];
                    textColor = Colors.green[800];
                  } else if (lower.contains('unhealthy')) {
                    // ⚠️ Unhealthy → yellow/orange
                    bgColor = Colors.yellow[100];
                    textColor = Colors.orange[800];
                  } else {
                    // 🔴 Default (e.g., "No plant detected" or unknown)
                    bgColor = Colors.red[50];
                    textColor = Colors.red[800];
                  }

                  return Card(
                    color: bgColor,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _result!,
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }
}
