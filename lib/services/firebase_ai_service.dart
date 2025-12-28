import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../main.dart'; // for log()

class FirebaseAIService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Fetch base64 image and decode
  Future<Uint8List?> fetchAndDecodeImage(String nodePath) async {
    try {
      log('Fetching Base64 image from: $nodePath');
      final snapshot = await _db.child(nodePath).get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final base64String = data['b64'] as String?;
        if (base64String != null) {
          return base64Decode(base64String);
        }
      }
      return null;
    } catch (e) {
      log('Error fetching image: $e');
      return null;
    }
  }

  // Analyze with Gemini via Firebase AI
  Future<String> analyzeImageWithGemini(Uint8List imageBytes) async {
    const prompt = '''
Analyze this JPEG image of a plant leaf.
Is there any noticeable discoloration, yellowing, or spotting?
Respond ONLY with:
"Healthy, no discoloration"
or
"Unhealthy: [issue description]"
If the image does not contain a plant, respond "No plant detected".
''';

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final result = response.text?.trim() ?? 'Analysis failed.';
      log('AI analysis result: $result');
      return result;
    } catch (e) {
      log('Error running Gemini analysis: $e');
      return 'Analysis error: $e';
    }
  }

  // Store AI result in RTDB
  Future<void> saveAnalysisResult(String timestamp, String result) async {
    try {
      // Step 1: Read the uploaded image data
      final uploadSnap = await _db.child('plantData/uploads/$timestamp').get();

      String? base64Image;
      String? contentType;

      if (uploadSnap.exists && uploadSnap.value is Map) {
        final data = uploadSnap.value as Map;
        base64Image = data['b64'] as String?;
        contentType = data['contentType'] as String? ?? 'image/jpeg';
      }

      // Step 2: Save AI analysis + image
      final analysisRef = _db.child('plantData/analysis/$timestamp');

      await analysisRef.set({
        'image': base64Image ?? '',
        'contentType': contentType,
        'status': result,
        'updated': ServerValue.timestamp,
      });

      log('✅ AI result + image saved successfully for $timestamp');
    } catch (e) {
      log('❌ Error saving AI result: $e');
    }
  }

  // Answer plant care questions using live sensor context
  Future<String> answerPlantQuestion({
    required String question,
    required Map<String, dynamic> sensorData,
  }) async {
    final prompt = '''
You are a plant care assistant for a smart irrigation system.
Use the live sensor data below to answer the user's question.
If data is missing or unclear, say so briefly.
Keep the response to 1-3 short sentences.
Do not invent actions or readings not shown in the data.

Live sensor data (JSON):
${jsonEncode(sensorData)}

User question: "$question"
''';

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final result = response.text?.trim() ?? 'I could not generate a reply.';
      log('AI chat response: $result');
      return result;
    } catch (e) {
      log('Error running Gemini chat: $e');
      return 'Chat error: $e';
    }
  }

  // High-level helper: fetch → analyze → save
  Future<String> processLatestUpload(String nodePath, String timestamp) async {
    final imageBytes = await fetchAndDecodeImage(nodePath);
    if (imageBytes == null) return 'No image found or decoding failed.';

    final result = await analyzeImageWithGemini(imageBytes);
    await saveAnalysisResult(timestamp, result);
    return result;
  }
}
