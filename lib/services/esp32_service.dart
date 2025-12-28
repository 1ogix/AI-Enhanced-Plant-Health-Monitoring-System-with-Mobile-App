import 'dart:async';
import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';

class ESP32Service {
  // Base URL for the ESP32; override at runtime with:
  // flutter run --dart-define=ESP32_BASE_URL=http://<esp32-ip>
  static final String baseUrl = const String.fromEnvironment(
    'ESP32_BASE_URL',
    defaultValue: 'http://192.168.1.100',
  );

  static const Duration defaultTimeout = Duration(seconds: 8);

  // Singleton pattern
  static final ESP32Service _instance = ESP32Service._internal();
  factory ESP32Service() => _instance;
  ESP32Service._internal();

  // Connection status stream
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  // Last known connection status
  ConnectionStatus _lastStatus = ConnectionStatus.unknown;
  ConnectionStatus get lastStatus => _lastStatus;

  // Timer for periodic connection checks
  Timer? _connectionTimer;

  // Log messages stream
  final _logMessagesController = StreamController<String>.broadcast();
  Stream<String> get logMessages => _logMessagesController.stream;

  // Initialize connection monitoring
  void startConnectionMonitoring(
      {Duration checkInterval = const Duration(seconds: 10)}) {
    // Cancel any existing timer
    _connectionTimer?.cancel();

    // Start periodic checking
    _connectionTimer = Timer.periodic(checkInterval, (_) {
      checkConnection();
    });

    // Do an immediate check
    checkConnection();
  }

  // Stop connection monitoring
  void stopConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  // Check connection to ESP32
  Future<ConnectionStatus> checkConnection() async {
    final statusUri = Uri.parse('$baseUrl/api/status');

    try {
      final response = await http.get(statusUri).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        _log('ESP32 connected successfully');
        _updateStatus(ConnectionStatus.connected);
        return ConnectionStatus.connected;
      } else {
        _log('ESP32 connection error: HTTP ${response.statusCode}');
        _updateStatus(ConnectionStatus.error);
        return ConnectionStatus.error;
      }
    } on TimeoutException {
      _log('ESP32 connection timeout');
      _updateStatus(ConnectionStatus.timeout);
      return ConnectionStatus.timeout;
    } catch (e) {
      _log('ESP32 connection error: $e');
      _updateStatus(ConnectionStatus.error);
      return ConnectionStatus.error;
    }
  }

  // Get sensor data with error handling
  Future<Map<String, dynamic>?> getSensorData() async {
    final sensorUri = Uri.parse('$baseUrl/api/sensor-data');

    try {
      final response = await http.get(sensorUri).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        _updateStatus(ConnectionStatus.connected);
        // In a real app, you would parse the JSON response
        return {'status': 'success', 'data': response.body};
      } else {
        _updateStatus(ConnectionStatus.error);
        return null;
      }
    } on TimeoutException {
      _updateStatus(ConnectionStatus.timeout);
      return null;
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      return null;
    }
  }

  // Private method to update status
  void _updateStatus(ConnectionStatus status) {
    if (_lastStatus != status) {
      _lastStatus = status;
      _connectionStatusController.add(status);
    }
  }

  // Log messages
  void _log(String message) {
    _logMessagesController.add(message);
  }

  // Dispose resources
  void dispose() {
    _connectionTimer?.cancel();
    _connectionStatusController.close();
    _logMessagesController.close();
  }
}

// Enum for connection status
enum ConnectionStatus { unknown, connected, timeout, error }

// Widget to display ESP32 connection status
// class ESP32ConnectionStatusWidget extends StatelessWidget {
//   final bool showDetailedError;
  
//   const ESP32ConnectionStatusWidget({
//     Key? key, 
//     this.showDetailedError = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<ConnectionStatus>(
//       stream: ESP32Service().connectionStatus,
//       initialData: ESP32Service().lastStatus,
//       builder: (context, snapshot) {
//         final status = snapshot.data ?? ConnectionStatus.unknown;
        
//         // Return appropriate UI based on connection status
//         switch (status) {
//           case ConnectionStatus.connected:
//             return const SizedBox.shrink(); // No banner when connected
            
//           case ConnectionStatus.timeout:
//             return _buildStatusBanner(
//               context,
//               Colors.orange,
//               'ESP32 Connection Timeout',
//               showDetailedError 
//                   ? 'Unable to connect to ESP32. Make sure both devices are on the same WiFi network (SSID: DEANDRE 2.4)' 
//                   : null,
//             );
            
//           case ConnectionStatus.error:
//             return _buildStatusBanner(
//               context,
//               Colors.red,
//               'ESP32 Connection Error',
//               showDetailedError ? 'Failed to connect to ESP32 device' : null,
//             );
            
//           case ConnectionStatus.unknown:
//           default:
//             return _buildStatusBanner(
//               context,
//               Colors.grey,
//               'ESP32 Status Unknown',
//               showDetailedError ? 'Checking connection to ESP32...' : null,
//             );
//         }
//       },
//     );
//   }
  
//   // Helper to build status banner
//   Widget _buildStatusBanner(
//     BuildContext context,
//     Color color,
//     String title,
//     String? details,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       color: color.withOpacity(0.2),
//       child: Row(
//         children: [
//           Icon(Icons.wifi_off, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//                 if (details != null)
//                   Text(
//                     details,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: color.withOpacity(0.8),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
