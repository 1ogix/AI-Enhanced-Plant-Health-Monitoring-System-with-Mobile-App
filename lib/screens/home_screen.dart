import 'package:flutter/material.dart';
import '../models/plant_data.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_db_service.dart';
import '../services/esp32_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final bool isFirebaseInitialized;

  const HomeScreen({super.key, this.isFirebaseInitialized = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantData _plantData = PlantData();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseDbService _dbService = FirebaseDbService();
  final ESP32Service _esp32Service = ESP32Service();
  bool _isLoading = true;
  String _connectionStatus = 'Checking connection...';
  bool _hasConnectionError = false;
  StreamSubscription<User?>? _authSubscription;

  // Format for timestamps
  final DateFormat _dateFormat = DateFormat('HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (!widget.isFirebaseInitialized) return;
      if (user != null) {
        _initializeServices();
      } else {
        if (mounted) {
          setState(() {
            _hasConnectionError = true;
            _connectionStatus =
                'Not logged in to Firebase. Please log in from Settings.';
          });
        }
      }
    });
    _initializeServices();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Initializing services...';
    });

    try {
      // Only attempt to use Firebase if it's initialized
      if (widget.isFirebaseInitialized) {
        await _dbService.initialize();

        // Get initial data
        await _refreshData();

        // Listen for connection status changes
        _setupConnectionListeners();
      } else {
        setState(() {
          _hasConnectionError = true;
          _connectionStatus =
              'Firebase not initialized. Check your connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing services: $e');
      setState(() {
        _hasConnectionError = true;
        _connectionStatus = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _setupConnectionListeners() {
    // Listen for Firebase Database connection status
    _dbService.connectionStatusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          if (isConnected) {
            _hasConnectionError = false;
            _connectionStatus = 'Connected to Firebase';
            _refreshData(); // Refresh data when connection is established
          } else {
            _hasConnectionError = true;
            _connectionStatus = 'Disconnected from Firebase';
          }
        });
      }
    });

    // Listen for ESP32 connection status
    _esp32Service.connectionStatus.listen((status) {
      if (mounted) {
        setState(() {
          if (status == ConnectionStatus.connected) {
            _connectionStatus = 'Connected to ESP32';
          } else if (!_hasConnectionError) {
            // Only update if we don't already have a Firebase error
            _connectionStatus = 'Disconnected from ESP32';
          }
        });
      }
    });
  }

  Future<void> _refreshData() async {
    if (!widget.isFirebaseInitialized) {
      setState(() {
        _isLoading = false;
        _hasConnectionError = true;
        _connectionStatus = 'Firebase not initialized. Check your connection.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _dbService.getLatestSensorData();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasConnectionError = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasConnectionError = true;
          _connectionStatus = 'Error fetching data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.green.withOpacity(0.8),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<double>(
          stream: _plantData.temperatureStream,
          initialData: _plantData.temperature,
          builder: (context, waterTempSnapshot) {
            return StreamBuilder<double>(
              stream: _plantData.soilMoistureStream,
              initialData: _plantData.soilMoisture.toDouble(),
              builder: (context, moistureSnapshot) {
                // Water level StreamBuilder has been removed
                return StreamBuilder<Map<String, dynamic>>(
                  stream: _dbService.sensorDataStream(),
                  initialData: const <String, dynamic>{},
                  builder: (context, dataSnapshot) {
                    final data = dataSnapshot.data;
                    final airTemp = _getDoubleValue(
                      data?['dhtTemperature'],
                      fallback: _plantData.dhtTemperature,
                    );
                    final humidity = _getDoubleValue(
                      data?['humidity'],
                      fallback: _plantData.humidity,
                    );
                    final soil1 = _getDoubleValue(
                      data?['soilMoisture1'],
                      fallback: moistureSnapshot.data ?? 0,
                    );
                    final waterTemp = _getDoubleValue(
                      data?['ntcTemperature'],
                      fallback: waterTempSnapshot.data ?? 0,
                    );
                    final soil2 = _getDoubleValue(data?['soilMoisture2']);
                    final soil3 = _getDoubleValue(data?['soilMoisture3']);
                    final healthStatus = _computePlantHealth(
                      data: data,
                      soil1: soil1,
                      soil2: soil2,
                      soil3: soil3,
                      waterTemp: waterTemp,
                      airTemp: airTemp,
                      humidity: humidity,
                    );
                    final pump1 = _getBoolValue(
                      _getNestedValue(data, ['pumpStatuses', 'pump1']),
                    );
                    final pump2 = _getBoolValue(
                      _getNestedValue(data, ['pumpStatuses', 'pump2']),
                    );
                    final pump3 = _getBoolValue(
                      _getNestedValue(data, ['pumpStatuses', 'pump3']),
                    );
                    final fanActive = _getBoolValue(
                      _getNestedValue(data, ['fan', 'actual']),
                      fallback: _plantData.fanStatus,
                    );
                    final ledActive = _getBoolValue(
                      _getNestedValue(data, ['led', 'actual']),
                      fallback: _plantData.ledStatus,
                    );
                    final coolingActive = _getBoolValue(
                      _getNestedValue(data, ['cooling', 'actual']),
                      fallback: _plantData.ntcRelayStatus,
                    );

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Plant health status card
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Plant Health Status:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    healthStatus,
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: _getHealthColor(healthStatus),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Temperature and soil moisture
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildMetricItem(
                                          'Air Temp',
                                          '${airTemp.toStringAsFixed(1)}°C',
                                          Icons.thermostat),
                                      _buildMetricItem(
                                          'Humidity',
                                          '${humidity.toStringAsFixed(1)}%',
                                          Icons.opacity),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildMetricItem(
                                          'Water Temp',
                                          '${waterTemp.toStringAsFixed(1)}°C',
                                          Icons.waves),
                                      _buildMetricItem(
                                          'Soil 1',
                                          '${soil1.toStringAsFixed(1)}%',
                                          Icons.water_drop),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildMetricItem(
                                          'Soil 2',
                                          '${soil2.toStringAsFixed(1)}%',
                                          Icons.water_drop),
                                      _buildMetricItem(
                                          'Soil 3',
                                          '${soil3.toStringAsFixed(1)}%',
                                          Icons.water_drop),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatusItem(
                                          'Fan', fanActive, Icons.air),
                                      _buildStatusItem(
                                          'LED', ledActive, Icons.lightbulb),
                                      _buildStatusItem('Cooling', coolingActive,
                                          Icons.ac_unit),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatusItem(
                                          'Pump 1', pump1, Icons.water),
                                      _buildStatusItem(
                                          'Pump 2', pump2, Icons.water),
                                      _buildStatusItem(
                                          'Pump 3', pump3, Icons.water),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Connection information
                          StreamBuilder<bool>(
                            stream: _dbService.connectionStatusStream,
                            initialData: _dbService.isConnected,
                            builder: (context, connectionSnapshot) {
                              final bool isConnected =
                                  connectionSnapshot.data ?? false;
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isConnected
                                                ? Icons.cloud_done
                                                : Icons.cloud_off,
                                            color: isConnected
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isConnected
                                                ? 'Connected to Firebase'
                                                : 'Disconnected from Firebase',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isConnected
                                            ? 'Receiving real-time sensor data from Firebase Realtime Database.'
                                            : 'Using simulated data. Check your internet connection.',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Last updated: ${_dateFormat.format(DateTime.now())}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Add refresh button to manually fetch data
                                      isConnected
                                          ? ElevatedButton.icon(
                                              onPressed: () async {
                                                await _plantData.refreshData();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Data refreshed from Firebase'),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Refresh Data'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _getDoubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _getBoolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is num) return value != 0;
    return fallback;
  }

  dynamic _getNestedValue(Map<String, dynamic>? data, List<String> path) {
    dynamic current = data;
    for (final key in path) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isActive, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String health) {
    switch (health) {
      case 'HEALTHY':
        return Colors.green;
      case 'STRESSED':
        return Colors.orange;
      case 'NEEDS WATER':
        return Colors.blue;
      case 'OVERWATERED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _computePlantHealth({
    required Map<String, dynamic>? data,
    required double soil1,
    required double soil2,
    required double soil3,
    required double waterTemp,
    required double airTemp,
    required double humidity,
  }) {
    final soilStatus1 = _getNestedValue(data, ['soils', '1', 'status']);
    final soilStatus2 = _getNestedValue(data, ['soils', '2', 'status']);
    final soilStatus3 = _getNestedValue(data, ['soils', '3', 'status']);
    final hasDisconnectedSoil = [soilStatus1, soilStatus2, soilStatus3]
        .any((status) => status is String && status != 'OK');

    final soilAvg = _averageSoil([soil1, soil2, soil3]);

    if (hasDisconnectedSoil) return 'STRESSED';
    if (soilAvg < 30) return 'NEEDS WATER';
    if (soilAvg > 85) return 'OVERWATERED';
    if (waterTemp >= 32 || airTemp >= 32 || humidity >= 85) {
      return 'STRESSED';
    }
    return 'HEALTHY';
  }

  double _averageSoil(List<double> values) {
    if (values.isEmpty) return 0;
    final total = values.fold<double>(0, (sum, v) => sum + v);
    return total / values.length;
  }
}
