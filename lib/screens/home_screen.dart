import 'package:flutter/material.dart';
import '../models/plant_data.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_db_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantData _plantData = PlantData();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseDbService _dbService = FirebaseDbService();

  // Format for timestamps
  final DateFormat _dateFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Monitor'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();
              // No need to navigate, AuthGate will handle it
            },
          ),
        ],
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
              builder: (context, tempSnapshot) {
                return StreamBuilder<int>(
                  stream: _plantData.soilMoistureStream,
                  initialData: _plantData.soilMoisture,
                  builder: (context, moistureSnapshot) {
                    // Water level StreamBuilder has been removed
                    return Column(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _authService.currentUser?.email ?? 'User',
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
                                  'Plant Health:',
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
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Temperature:'),
                                        Text(
                                          '${tempSnapshot.data?.toStringAsFixed(1) ?? "0.0"}°C',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Soil Moisture:'),
                                        Text(
                                          '${moistureSnapshot.data ?? "0"}%',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
