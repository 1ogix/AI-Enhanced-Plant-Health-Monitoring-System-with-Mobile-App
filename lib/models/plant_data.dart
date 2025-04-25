import 'dart:async';
import '../services/firebase_db_service.dart';

class PlantData {
  // Singleton pattern
  static final PlantData _instance = PlantData._internal();

  factory PlantData() {
    return _instance;
  }

  // Firebase database service
  final FirebaseDbService _firebaseDbService = FirebaseDbService();

  // Current sensor values
  double temperature = 0.0;
  int soilMoisture = 0;
  int lightExposure = 0;
  double soilPh = 0.0;
  int nutrientLevel = 0;
  String plantHealth = 'UNKNOWN';
  bool isConnectedToFirebase = false;

  // Historical data (last 7 days)
  final List<double> temperatureHistory = [];
  final List<int> soilMoistureHistory = [];
  final List<int> lightExposureHistory = [];
  final List<double> soilPhHistory = [];
  final List<int> nutrientLevelHistory = [];

  // Stream controllers for real-time updates
  final _temperatureController = StreamController<double>.broadcast();
  final _soilMoistureController = StreamController<int>.broadcast();
  final _plantHealthController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<int> get soilMoistureStream => _soilMoistureController.stream;
  Stream<String> get plantHealthStream => _plantHealthController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get logMessages => _firebaseDbService.logMessages;

  // Timer for data fetching
  Timer? _dataFetchTimer;
  Timer? _simulationTimer;
  bool _useSimulation = true;

  // Subscribe to the Firebase stream
  StreamSubscription? _firebaseDataSubscription;

  PlantData._internal() {
    // Initialize with default values
    temperature = 0.0;
    soilMoisture = 0;
    plantHealth = 'UNKNOWN';

    // Initialize history data
    for (int i = 0; i < 7; i++) {
      temperatureHistory.add(0.0);
      soilMoistureHistory.add(0);
      lightExposureHistory.add(0);
      soilPhHistory.add(0.0);
      nutrientLevelHistory.add(0);
    }

    // Listen to Firebase connection status
    _firebaseDbService.connectionStatusStream.listen((connected) {
      isConnectedToFirebase = connected;
      _connectionStatusController.add(connected);

      if (connected) {
        _useSimulation = false;
        stopSimulation();
        _setupFirebaseDataStream();
        _fetchHistoricalData();
      } else {
        _useSimulation = true;
        _closeFirebaseDataStream();
        _startSimulation();
      }
    });
  }

  void _setupFirebaseDataStream() {
    // Close any existing subscription
    _closeFirebaseDataStream();

    // Subscribe to real-time updates
    _firebaseDataSubscription =
        _firebaseDbService.sensorDataStream().listen((data) {
      if (data.isNotEmpty) {
        _updateFromFirebaseData(data);
      }
    });
  }

  void _closeFirebaseDataStream() {
    _firebaseDataSubscription?.cancel();
    _firebaseDataSubscription = null;
  }

  Future<void> _fetchHistoricalData() async {
    final historicalData = await _firebaseDbService.getHistoricalData(7);

    if (historicalData.isNotEmpty) {
      // Clear existing history
      temperatureHistory.clear();
      soilMoistureHistory.clear();
      lightExposureHistory.clear();
      soilPhHistory.clear();
      nutrientLevelHistory.clear();

      // Sort by timestamp if available
      historicalData.sort((a, b) {
        final aTime = a['timestamp'] as int?;
        final bTime = b['timestamp'] as int?;
        if (aTime != null && bTime != null) {
          return aTime.compareTo(bTime);
        }
        return 0;
      });

      // Add to history lists
      for (final entry in historicalData) {
        if (entry.containsKey('temperature')) {
          temperatureHistory.add(_getDoubleValue(entry['temperature']));
        }

        if (entry.containsKey('soilMoisture')) {
          soilMoistureHistory.add(_getIntValue(entry['soilMoisture']));
        }

        if (entry.containsKey('lightExposure')) {
          lightExposureHistory.add(_getIntValue(entry['lightExposure']));
        }

        if (entry.containsKey('soilPh')) {
          soilPhHistory.add(_getDoubleValue(entry['soilPh']));
        }

        if (entry.containsKey('nutrientLevel')) {
          nutrientLevelHistory.add(_getIntValue(entry['nutrientLevel']));
        }
      }
    }
  }

  // Helper methods to safely convert values
  double _getDoubleValue(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _getIntValue(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  void _updateFromFirebaseData(Map<String, dynamic> data) {
    // Update temperature
    if (data.containsKey('temperature')) {
      final newTemp = _getDoubleValue(data['temperature']);
      updateTemperature(newTemp);
    }

    // Update soil moisture
    if (data.containsKey('soilMoisture')) {
      final newMoisture = _getIntValue(data['soilMoisture']);
      updateSoilMoisture(newMoisture);
    }

    // Update plant health if provided
    if (data.containsKey('plantHealth')) {
      String newHealth = data['plantHealth'].toString();
      plantHealth = newHealth;
      _plantHealthController.add(newHealth);
    } else {
      // Otherwise calculate it based on sensor data
      _updatePlantHealth();
    }

    // Update light exposure
    if (data.containsKey('lightExposure')) {
      final newLight = _getIntValue(data['lightExposure']);
      updateLightExposure(newLight);
    }

    // Update soil pH
    if (data.containsKey('soilPh')) {
      final newPh = _getDoubleValue(data['soilPh']);
      updateSoilPh(newPh);
    }

    // Update nutrient level
    if (data.containsKey('nutrientLevel')) {
      final newNutrient = _getIntValue(data['nutrientLevel']);
      updateNutrientLevel(newNutrient);
    }
  }

  // Methods to update values
  void updateTemperature(double value) {
    temperature = value;
    _temperatureController.add(value);

    // Update health status based on temperature if not using Firebase's health status
    if (!isConnectedToFirebase) {
      _updatePlantHealth();
    }

    // Add to history (remove oldest, add newest)
    if (temperatureHistory.length >= 7) {
      temperatureHistory.removeAt(0);
    }
    temperatureHistory.add(value);
  }

  void updateSoilMoisture(int value) {
    soilMoisture = value;
    _soilMoistureController.add(value);

    // Update health status if not using Firebase's health status
    if (!isConnectedToFirebase) {
      _updatePlantHealth();
    }

    // Add to history
    if (soilMoistureHistory.length >= 7) {
      soilMoistureHistory.removeAt(0);
    }
    soilMoistureHistory.add(value);
  }

  void updateLightExposure(int value) {
    lightExposure = value;

    // Add to history
    if (lightExposureHistory.length >= 7) {
      lightExposureHistory.removeAt(0);
    }
    lightExposureHistory.add(value);
  }

  void updateSoilPh(double value) {
    soilPh = value;

    // Add to history
    if (soilPhHistory.length >= 7) {
      soilPhHistory.removeAt(0);
    }
    soilPhHistory.add(value);
  }

  void updateNutrientLevel(int value) {
    nutrientLevel = value;

    // Add to history
    if (nutrientLevelHistory.length >= 7) {
      nutrientLevelHistory.removeAt(0);
    }
    nutrientLevelHistory.add(value);
  }

  // Private method to determine plant health based on sensor values
  void _updatePlantHealth() {
    // Simple logic for demonstration
    if (temperature < 15 || temperature > 35) {
      plantHealth = 'STRESSED';
    } else if (soilMoisture < 30) {
      plantHealth = 'NEEDS WATER';
    } else if (soilMoisture > 80) {
      plantHealth = 'OVERWATERED';
    } else {
      plantHealth = 'HEALTHY';
    }

    _plantHealthController.add(plantHealth);
  }

  // Simulation for demo purposes
  void _startSimulation() {
    if (!_useSimulation) return;

    // Cancel any existing simulation
    _simulationTimer?.cancel();

    // Start with some realistic values
    temperature = 25.0;
    soilMoisture = 55;
    lightExposure = 65;
    soilPh = 6.5;
    nutrientLevel = 70;
    _updatePlantHealth();

    // Send initial values to streams
    _temperatureController.add(temperature);
    _soilMoistureController.add(soilMoisture);
    _plantHealthController.add(plantHealth);

    // Update values every 3 seconds with slight variations
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Simulate temperature changes
      temperature += (DateTime.now().second % 2 == 0 ? 0.3 : -0.2);
      temperature = temperature.clamp(18.0, 32.0);

      // Simulate soil moisture changes (decreasing slowly)
      soilMoisture -= 1;
      if (soilMoisture < 30) {
        // Simulate automatic watering when moisture gets too low
        soilMoisture = 75;
      }

      // Update values
      updateTemperature(temperature);
      updateSoilMoisture(soilMoisture);
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  // Method to manually fetch latest data from Firebase
  Future<void> refreshData() async {
    if (!isConnectedToFirebase) {
      return;
    }

    final data = await _firebaseDbService.getLatestSensorData();
    if (data != null && data.isNotEmpty) {
      _updateFromFirebaseData(data);
      return;
    }
  }

  // Method to clean up streams
  void dispose() {
    stopSimulation();
    _dataFetchTimer?.cancel();
    _closeFirebaseDataStream();
    _temperatureController.close();
    _soilMoistureController.close();
    _plantHealthController.close();
    _connectionStatusController.close();
    _firebaseDbService.dispose();
  }
}
