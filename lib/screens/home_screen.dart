import 'package:flutter/material.dart';
import '../models/plant_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantData _plantData = PlantData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Monitor'),
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
                                // Water level indicator has been removed
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Demo information
                        Card(
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
                                    Icon(Icons.info_outline,
                                        color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Simulated Mode',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Currently showing simulated sensor data. Values automatically update every 3 seconds.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Last updated: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  // _getWaterLevelColor method has been removed
}
