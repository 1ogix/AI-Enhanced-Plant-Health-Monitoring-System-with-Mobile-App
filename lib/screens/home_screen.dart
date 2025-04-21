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
                    return StreamBuilder<int>(
                      stream: _plantData.waterLevelStream,
                      initialData: _plantData.waterLevel,
                      builder: (context, waterSnapshot) {
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

                                    const SizedBox(height: 24),

                                    // Water level indicator
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Water level check:'),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value:
                                                (waterSnapshot.data ?? 0) / 100,
                                            minHeight: 20,
                                            backgroundColor: Colors.grey[300],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              _getWaterLevelColor(
                                                  waterSnapshot.data ?? 0),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${waterSnapshot.data ?? "0"}%'),
                                      ],
                                    ),
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

  Color _getWaterLevelColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 40) return Colors.orange;
    return Colors.blue;
  }
}

// import 'package:flutter/material.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // Sample data for demonstration
//   final String plantHealth = 'HEALTHY';
//   final double temperature = 27.0;
//   final int soilMoisture = 56;
//   final int waterLevel = 40;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Plant Monitor'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Plant health status card
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Plant Health:',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       plantHealth,
//                       style: const TextStyle(
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Temperature and soil moisture
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Temp:'),
//                             Text(
//                               '$temperature°C',
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Soil Moisture:'),
//                             Text(
//                               '$soilMoisture%',
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 24),

//                     // Water level indicator
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('Water level check:'),
//                         const SizedBox(height: 8),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: LinearProgressIndicator(
//                             value: waterLevel / 100,
//                             minHeight: 20,
//                             backgroundColor: Colors.grey[300],
//                             valueColor: const AlwaysStoppedAnimation<Color>(
//                                 Colors.blue),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text('$waterLevel%'),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 36),

//             // Camera button
//             // Container(
//             //   width: double.infinity,
//             //   child: ElevatedButton.icon(
//             //     icon: const Icon(Icons.camera_alt),
//             //     label: const Text('Capture Plant Image'),
//             //     onPressed: () {
//             //       // Image capture functionality would go here
//             //       ScaffoldMessenger.of(context).showSnackBar(
//             //         const SnackBar(
//             //             content: Text('Camera function not implemented yet')),
//             //       );
//             //     },
//             //     style: ElevatedButton.styleFrom(
//             //       padding: const EdgeInsets.symmetric(vertical: 16),
//             //       shape: RoundedRectangleBorder(
//             //         borderRadius: BorderRadius.circular(30),
//             //       ),
//             //       backgroundColor: Colors.green,
//             //       foregroundColor: Colors.white,
//             //     ),
//             //   ),
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }
