import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/firebase_auth_service.dart';
// import '../services/firebase_config.dart';

class FirebaseDbService {
  // Singleton pattern
  static final FirebaseDbService _instance = FirebaseDbService._internal();
  factory FirebaseDbService() => _instance;

  // Firebase database instance
  FirebaseDatabase? _database;
  bool _isInitialized = false;

  // Auth service to get user ID
  // final FirebaseAuthService _authService = FirebaseAuthService();

  // Log messages stream
  final _logMessagesController = StreamController<String>.broadcast();
  Stream<String> get logMessages => _logMessagesController.stream;

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Connection status stream
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  FirebaseDbService._internal();

  // Initialize Firebase
  Future<void> initialize() async {
    if (_isInitialized) {
      _logMessage('FirebaseDbService already initialized');
      return;
    }

    try {
      // Make sure Firebase is initialized before accessing FirebaseDatabase
      if (Firebase.apps.isEmpty) {
        _logMessage(
            'Firebase not initialized yet. Firebase.initializeApp() must be called first.');
        throw Exception('Firebase not initialized');
      }

      _database = FirebaseDatabase.instance;
      _isInitialized = true;
      _logMessage('Firebase database service initialized successfully');

      // Monitor connection state
      try {
        final connectedRef = _database!.ref('.info/connected');
        connectedRef.onValue.listen((event) {
          _isConnected = event.snapshot.value as bool? ?? false;
          _connectionStatusController.add(_isConnected);

          if (_isConnected) {
            _logMessage('Connected to Firebase Realtime Database');
          } else {
            _logMessage('Disconnected from Firebase Realtime Database');
          }
        });
      } catch (e) {
        _logMessage('Error setting up connection monitoring: $e');
        // Don't throw - we still want to consider the service initialized
      }
    } catch (e) {
      _logMessage('Error initializing Firebase: $e');
      _isInitialized = false;
      throw e; // Rethrow to notify caller
    }
  }

  // Check if initialized before any database operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        throw Exception('Firebase database service is not initialized');
      }
    }
  }

  // Get latest sensor data
  Future<Map<String, dynamic>?> getLatestSensorData() async {
    try {
      await _ensureInitialized();

      if (_database == null) {
        _logMessage('Database instance is null, returning empty data');
        return null;
      }

      // Match the ESP32 database path "plantData/current"
      final ref = _database!.ref('plantData/current');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;

        // Convert to Map<String, dynamic>
        final convertedData = <String, dynamic>{};
        data.forEach((key, value) {
          if (key is String) {
            convertedData[key] = value;
          }
        });

        _logMessage('Received sensor data: $convertedData');
        return convertedData;
      } else {
        _logMessage('No sensor data found');
        return null;
      }
    } catch (e) {
      _logMessage('Error fetching sensor data: $e');
      return null;
    }
  }

  // Get historical sensor data
  Future<List<Map<String, dynamic>>> getHistoricalData(int days) async {
    try {
      await _ensureInitialized();

      if (_database == null) {
        _logMessage(
            'Database instance is null, returning empty historical data');
        return [];
      }

      // Match the ESP32 database path "plantData/history"
      final ref = _database!.ref('plantData/history');

      // Query the most recent entries
      final query = ref.limitToLast(days);
      final snapshot = await query.get();

      final List<Map<String, dynamic>> result = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;

        data.forEach((key, value) {
          if (value is Map<Object?, Object?>) {
            final entry = <String, dynamic>{};
            value.forEach((k, v) {
              if (k is String) {
                entry[k] = v;
              }
            });

            // Add timestamp from the key if it exists
            if (key is String) {
              // Try to convert key to timestamp if it's a string representation of a number
              try {
                final timestamp = int.parse(key);
                entry['timestamp'] = timestamp;
              } catch (e) {
                // If key is not a number, just use it as-is
                entry['key'] = key;
              }
            }

            result.add(entry);
          }
        });

        _logMessage('Received historical data: ${result.length} entries');
      } else {
        _logMessage('No historical data found');
      }

      return result;
    } catch (e) {
      _logMessage('Error fetching historical data: $e');
      return [];
    }
  }

  // Listen for real-time updates to sensor data
  Stream<Map<String, dynamic>> sensorDataStream() {
    if (!_isInitialized || _database == null) {
      _logMessage('Cannot create sensor data stream, service not initialized');
      // Return empty stream
      return Stream.value(<String, dynamic>{});
    }

    // Match the Firebase path shown in the image: plantData/current
    final ref = _database!.ref('plantData/current');
    return ref.onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<Object?, Object?>;

        // Convert to Map<String, dynamic>
        final convertedData = <String, dynamic>{};
        data.forEach((key, value) {
          if (key is String) {
            convertedData[key] = value;
          }
        });

        _logMessage('Received real-time sensor data update: $convertedData');
        return convertedData;
      } else {
        _logMessage('Real-time sensor data is empty');
        return <String, dynamic>{};
      }
    });
  }

  // Get irrigation settings
  Future<Map<String, dynamic>?> getIrrigationSettings() async {
    try {
      await _ensureInitialized();

      if (_database == null) {
        _logMessage(
            'Database instance is null, returning null irrigation settings');
        return null;
      }

      final ref = _database!.ref('plantData/irrigationSettings');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;

        // Convert to Map<String, dynamic>
        final convertedData = <String, dynamic>{};
        data.forEach((key, value) {
          if (key is String) {
            convertedData[key] = value;
          }
        });

        _logMessage('Received irrigation settings: $convertedData');
        return convertedData;
      } else {
        _logMessage('No irrigation settings found');
        return null;
      }
    } catch (e) {
      _logMessage('Error fetching irrigation settings: $e');
      return null;
    }
  }

  // Save irrigation settings
  Future<void> saveIrrigationSettings(Map<String, dynamic> settings) async {
    try {
      await _ensureInitialized();

      if (_database == null) {
        _logMessage(
            'Database instance is null, cannot save irrigation settings');
        throw Exception('Database not initialized');
      }

      final ref = _database!.ref('plantData/irrigationSettings');
      await ref.set(settings);
      _logMessage('Saved irrigation settings: $settings');
    } catch (e) {
      _logMessage('Error saving irrigation settings: $e');
      rethrow;
    }
  }

  void _logMessage(String message) {
    print('FirebaseDbService: $message');
    _logMessagesController.add(message);
  }

  void dispose() {
    _logMessagesController.close();
    _connectionStatusController.close();
  }
}
