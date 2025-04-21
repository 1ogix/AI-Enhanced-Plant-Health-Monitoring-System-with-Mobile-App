import 'dart:async';
import 'dart:convert';
import '../services/http_client.dart';

class ESP32Service {
  // Singleton pattern
  static final ESP32Service _instance = ESP32Service._internal();
  factory ESP32Service() => _instance;

  // ESP32 AP Default IP
  String ipAddress = '192.168.4.1';

  // HTTP client for making requests
  final _httpClient = HttpClient();

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Connection status stream
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // Log messages stream
  final _logMessagesController = StreamController<String>.broadcast();
  Stream<String> get logMessages => _logMessagesController.stream;

  // Timer for periodic connection check
  Timer? _connectionCheckTimer;

  ESP32Service._internal() {
    // Start connection check timer
    _startConnectionCheck();
  }

  void _startConnectionCheck() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkConnection();
    });
  }

  Future<void> checkConnection() async {
    try {
      final response =
          await _httpClient.get('http://$ipAddress/api/sensor-data');

      final wasConnected = _isConnected;
      _isConnected = response != null;

      // Only add to stream if status has changed
      if (wasConnected != _isConnected) {
        _connectionStatusController.add(_isConnected);

        if (_isConnected) {
          _logMessage('Connected to ESP32 at $ipAddress');
        } else {
          _logMessage('Disconnected from ESP32');
        }
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectionStatusController.add(false);
        _logMessage('Connection to ESP32 lost: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getSensorData() async {
    if (!_isConnected) {
      await checkConnection();
      if (!_isConnected) {
        _logMessage('Cannot fetch sensor data: Not connected to ESP32');
        return null;
      }
    }

    try {
      final data = await _httpClient.get('http://$ipAddress/api/sensor-data');

      if (data != null) {
        _logMessage('Received sensor data: ${json.encode(data)}');
        return data;
      } else {
        _logMessage('Error fetching sensor data');
        return null;
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      _logMessage('Error fetching sensor data: $e');
      return null;
    }
  }

  void _logMessage(String message) {
    print('ESP32Service: $message');
    _logMessagesController.add(message);
  }

  void updateIPAddress(String newIP) {
    ipAddress = newIP;
    _logMessage('ESP32 IP address updated to $newIP');
    checkConnection();
  }

  void dispose() {
    _connectionCheckTimer?.cancel();
    _connectionStatusController.close();
    _logMessagesController.close();
  }
}
