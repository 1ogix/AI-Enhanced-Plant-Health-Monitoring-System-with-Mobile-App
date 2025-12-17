import 'package:flutter/material.dart';
import '../models/plant_data.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_db_service.dart';
import '../services/esp32_service.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _latestData;
  bool _hasConnectionError = false;

  // Format for timestamps
  final DateFormat _dateFormat = DateFormat('HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
          _latestData = data;
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
        child: StreamBuilder<String>(
          stream: _plantData.plantHealthStream,
          initialData: _plantData.plantHealth,
          builder: (context, healthSnapshot) {
            return StreamBuilder<double>(
              stream: _plantData.temperatureStream,
              initialData: _plantData.temperature,
              builder: (context, waterTempSnapshot) {
                return StreamBuilder<double>(
                  stream: _plantData.soilMoistureStream,
                  initialData: _plantData.soilMoisture.toDouble(),
                  builder: (context, moistureSnapshot) {
                    // Water level StreamBuilder has been removed
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // User info card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child:
                                        Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _authService.currentUser?.email ??
                                            'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'User ID: ${_authService.userId?.substring(0, 8) ?? 'Unknown'}...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

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
                                    healthSnapshot.data ?? 'UNKNOWN',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: _getHealthColor(
                                          healthSnapshot.data ?? 'UNKNOWN'),
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
                                          '${_plantData.dhtTemperature.toStringAsFixed(1)}°C',
                                          Icons.thermostat),
                                      _buildMetricItem(
                                          'Humidity',
                                          '${_plantData.humidity.toStringAsFixed(1)}%',
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
                                          '${waterTempSnapshot.data?.toStringAsFixed(1) ?? "0.0"}°C',
                                          Icons.waves),
                                      _buildMetricItem(
                                          'Soil Moisture',
                                          '${moistureSnapshot.data?.toStringAsFixed(1) ?? "0.0"}%',
                                          Icons.water_drop),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatusItem('Fan',
                                          _plantData.fanStatus, Icons.air),
                                      _buildStatusItem(
                                          'LED',
                                          _plantData.ledStatus,
                                          Icons.lightbulb),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatusItem('Pump',
                                          _plantData.pumpStatus, Icons.water),
                                      _buildStatusItem(
                                          'NTC Relay',
                                          _plantData.ntcRelayStatus,
                                          Icons.power),
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
}
