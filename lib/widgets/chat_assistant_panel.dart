import 'package:flutter/material.dart';
import '../models/plant_data.dart';
import '../services/firebase_ai_service.dart';
import '../services/firebase_db_service.dart';

class ChatAssistantPanel extends StatefulWidget {
  final bool isFirebaseInitialized;

  const ChatAssistantPanel({
    super.key,
    required this.isFirebaseInitialized,
  });

  @override
  State<ChatAssistantPanel> createState() => _ChatAssistantPanelState();
}

class _ChatAssistantPanelState extends State<ChatAssistantPanel> {
  final PlantData _plantData = PlantData();
  final FirebaseAIService _aiService = FirebaseAIService();
  final FirebaseDbService _dbService = FirebaseDbService();
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [];
  bool _isChatLoading = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildAssistantContext(
      Map<String, dynamic>? latestSnapshot) {
    return {
      'plantHealth': _plantData.plantHealth,
      'airTemperatureC': _plantData.dhtTemperature,
      'humidityPercent': _plantData.humidity,
      'waterTemperatureC': _plantData.temperature,
      'soilMoisturePercent': _plantData.soilMoisture,
      'fanOn': _plantData.fanStatus,
      'ledOn': _plantData.ledStatus,
      'pumpOn': _plantData.pumpStatus,
      'ntcRelayOn': _plantData.ntcRelayStatus,
      'latestFirebaseSnapshot': latestSnapshot ?? <String, dynamic>{},
      'lastUpdatedIso': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _sendChatMessage() async {
    final question = _chatController.text.trim();
    if (question.isEmpty || _isChatLoading) return;

    setState(() {
      _chatMessages.add(_ChatMessage(text: question, isUser: true));
      _isChatLoading = true;
    });
    _chatController.clear();

    try {
      Map<String, dynamic>? latestSnapshot;
      if (widget.isFirebaseInitialized) {
        latestSnapshot = await _dbService.getLatestSensorData();
      }

      final response = await _aiService.answerPlantQuestion(
        question: question,
        sensorData: _buildAssistantContext(latestSnapshot),
      );
      if (!mounted) return;
      setState(() {
        _chatMessages.add(_ChatMessage(text: response, isUser: false));
        _isChatLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatMessages.add(_ChatMessage(
            text: 'Chat failed: $e', isUser: false, isError: true));
        _isChatLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask about the pump, stress status, or how to improve conditions.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final bubbleColor = message.isUser
                        ? Colors.green.shade50
                        : Colors.grey.shade200;
                    final textColor =
                        message.isError ? Colors.red : Colors.black87;
                    return Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendChatMessage(),
                decoration: const InputDecoration(
                  hintText: 'e.g., Why is the pump on?',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isChatLoading ? null : _sendChatMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isChatLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
