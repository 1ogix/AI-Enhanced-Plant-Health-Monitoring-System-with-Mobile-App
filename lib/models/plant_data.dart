import 'dart:async';
import '../services/esp32_service.dart';

class PlantData {
  // Singleton pattern
  static final PlantData _instance = PlantData._internal();

  factory PlantData() {
    return _instance;
  }

  // ESP32 service
  final ESP32Service _esp32Service = ESP32Service();

  // Current sensor values
  double temperature = 0.0;
  int soilMoisture = 0;
  int lightExposure = 0;
  double soilPh = 0.0;
  int nutrientLevel = 0;
  String plantHealth = 'UNKNOWN';
  bool isConnectedToESP32 = false;

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
  Stream<String> get logMessages => _esp32Service.logMessages;

  // Timer for data fetching
  Timer? _dataFetchTimer;
  Timer? _simulationTimer;
  bool _useSimulation = true;

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

    // Listen to ESP32 connection status
    _esp32Service.connectionStatusStream.listen((connected) {
      isConnectedToESP32 = connected;
      _connectionStatusController.add(connected);

      if (connected) {
        _useSimulation = false;
        stopSimulation();
        _startDataFetching();
      } else {
        _useSimulation = true;
        _dataFetchTimer?.cancel();
        _startSimulation();
      }
    });

    // Initial connection check
    _esp32Service.checkConnection().then((_) {
      if (_esp32Service.isConnected) {
        isConnectedToESP32 = true;
        _useSimulation = false;
        _connectionStatusController.add(true);
        _startDataFetching();
      } else {
        // Fall back to simulation if not connected
        _startSimulation();
      }
    });
  }

  void _startDataFetching() {
    // Cancel any existing timer
    _dataFetchTimer?.cancel();

    // Fetch data immediately
    _fetchSensorData();

    // Setup timer to fetch data every 3 seconds
    _dataFetchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchSensorData();
    });
  }

  Future<void> _fetchSensorData() async {
    final data = await _esp32Service.getSensorData();

    if (data != null) {
      // Update temperature
      if (data.containsKey('temperature')) {
        double newTemp = data['temperature'].toDouble();
        updateTemperature(newTemp);
      }

      // Update soil moisture
      if (data.containsKey('soilMoisture')) {
        int newMoisture = data['soilMoisture'].toInt();
        updateSoilMoisture(newMoisture);
      }

      // Update plant health if provided by ESP32
      if (data.containsKey('plantHealth')) {
        String newHealth = data['plantHealth'];
        plantHealth = newHealth;
        _plantHealthController.add(newHealth);
      } else {
        // Otherwise calculate it based on sensor data
        _updatePlantHealth();
      }
    }
  }

  // Methods to update values
  void updateTemperature(double value) {
    temperature = value;
    _temperatureController.add(value);

    // Update health status based on temperature if not using ESP32's health status
    if (!_esp32Service.isConnected) {
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

    // Update health status if not using ESP32's health status
    if (!_esp32Service.isConnected) {
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

  void connectToESP32(String ipAddress) {
    _esp32Service.updateIPAddress(ipAddress);
    _esp32Service.checkConnection();
  }

  // Method to clean up streams
  void dispose() {
    stopSimulation();
    _dataFetchTimer?.cancel();
    _temperatureController.close();
    _soilMoistureController.close();
    _plantHealthController.close();
    _connectionStatusController.close();
    _esp32Service.dispose();
  }
}
