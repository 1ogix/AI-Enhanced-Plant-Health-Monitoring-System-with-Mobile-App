import 'dart:async';

class SerialService {
  static final SerialService _instance = SerialService._internal();
  factory SerialService() => _instance;

  SerialService._internal();

  // Stream controller for log messages
  final _logMessagesController = StreamController<String>.broadcast();
  Stream<String> get logMessages => _logMessagesController.stream;

  // This is a simplified service that doesn't actually connect to hardware
  // It's meant just to make the app compile and run for now

  void dispose() {
    _logMessagesController.close();
  }
}
