import 'package:flutter/material.dart';
import '../models/plant_data.dart'; // Import the PlantData model
import '../widgets/custom_charts.dart';
import '../services/firebase_db_service.dart';

class PlantHealthScreen extends StatefulWidget {
  final bool isFirebaseInitialized;

  const PlantHealthScreen({super.key, this.isFirebaseInitialized = false});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  // Get instance of PlantData singleton
  final PlantData _plantData = PlantData();
  final FirebaseDbService _dbService = FirebaseDbService();

  // Sample data for demonstration
  late List<Map<String, dynamic>> _healthMetrics;

  // History data for charts
  late List<List<double>> _historyData;

  static const int _historyLength = 7;

  // Labels for last N updates (oldest -> newest)
  final List<String> _lastSevenUpdates = [
    '7th',
    '6th',
    '5th',
    '4th',
    '3rd',
    'Recent',
    'Current',
  ];

  int _selectedMetricIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize history data
    _initializeHistoryData();
    // Initialize the health metrics with current plant data
    _initializeHealthMetrics();
  }

  // Initialize history data with current in-memory values
  void _initializeHistoryData() {
    _historyData = [
      List<double>.filled(_historyLength, _plantData.soilMoisture,
          growable: true),
      List<double>.filled(_historyLength, _plantData.soilMoisture,
          growable: true),
      List<double>.filled(_historyLength, _plantData.soilMoisture,
          growable: true),
      List<double>.filled(_historyLength, _plantData.temperature,
          growable: true),
      List<double>.filled(_historyLength, _plantData.dhtTemperature,
          growable: true),
      List<double>.filled(_historyLength, _plantData.humidity, growable: true),
    ];
  }

  final List<double?> _lastHistoryValues = List<double?>.filled(6, null);

  void _appendHistory(int index, double value) {
    if (_lastHistoryValues[index] == value) return;
    _lastHistoryValues[index] = value;

    _historyData[index].add(value);
    if (_historyData[index].length > _historyLength) {
      _historyData[index] = _historyData[index]
          .sublist(_historyData[index].length - _historyLength);
    }
  }

  // Initialize health metrics with current plant data
  void _initializeHealthMetrics() {
    _healthMetrics = [
      {
        'name': 'Soil Moisture 1',
        'value': _plantData.soilMoisture,
        'unit': '%',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'recommendation': 'Optimal range: 40-60%',
        'status': _getStatusForMoisture(_plantData.soilMoisture.toInt()),
      },
      {
        'name': 'Soil Moisture 2',
        'value': _plantData.soilMoisture,
        'unit': '%',
        'icon': Icons.water_drop,
        'color': Colors.blueGrey,
        'recommendation': 'Optimal range: 40-60%',
        'status': _getStatusForMoisture(_plantData.soilMoisture.toInt()),
      },
      {
        'name': 'Soil Moisture 3',
        'value': _plantData.soilMoisture,
        'unit': '%',
        'icon': Icons.water_drop,
        'color': Colors.indigo,
        'recommendation': 'Optimal range: 40-60%',
        'status': _getStatusForMoisture(_plantData.soilMoisture.toInt()),
      },
      {
        'name': 'Water Temperature',
        'value': _plantData.ntcTemperature,
        'unit': '°C',
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'recommendation': 'Optimal range: 20-28°C',
        'status': _getStatusForTemperature(_plantData.temperature),
      },
      {
        'name': 'Air Temperature',
        'value': _plantData.dhtTemperature,
        'unit': '°C',
        'icon': Icons.thermostat_auto,
        'color': Colors.red,
        'recommendation': 'Optimal range: 22-30°C',
        'status': _getStatusForDhtTemperature(_plantData.dhtTemperature),
      },
      {
        'name': 'Humidity',
        'value': _plantData.humidity,
        'unit': '%',
        'icon': Icons.opacity,
        'color': Colors.teal,
        'recommendation': 'Optimal range: 50-70%',
        'status': _getStatusForHumidity(_plantData.humidity),
      },
    ];
  }

  // Helper method to determine moisture status
  String _getStatusForMoisture(int moisture) {
    if (moisture >= 40 && moisture <= 60) {
      return 'Good';
    } else if (moisture < 30) {
      return 'Low';
    } else if (moisture > 80) {
      return 'High';
    } else {
      return 'Moderate';
    }
  }

  // Helper method to determine temperature status
  String _getStatusForTemperature(double temp) {
    if (temp >= 20 && temp <= 28) {
      return 'Good';
    } else if (temp < 15 || temp > 35) {
      return 'Critical';
    } else {
      return 'Moderate';
    }
  }

  // Helper method to determine DHT temperature status
  String _getStatusForDhtTemperature(double temp) {
    if (temp >= 22 && temp <= 30) {
      return 'Good';
    } else if (temp < 18 || temp > 35) {
      return 'Critical';
    } else {
      return 'Moderate';
    }
  }

  // Helper method to determine humidity status
  String _getStatusForHumidity(double humidity) {
    if (humidity >= 50 && humidity <= 70) {
      return 'Good';
    } else if (humidity < 40) {
      return 'Low';
    } else {
      return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_healthMetrics.length < 6 || _historyData.length < 6) {
      _initializeHistoryData();
      _initializeHealthMetrics();
      _selectedMetricIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Health Analysis'),
        backgroundColor: Colors.green.withOpacity(0.8),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
          stream: _dbService.sensorDataStream(),
          initialData: const <String, dynamic>{},
          builder: (context, dataSnapshot) {
            if (_healthMetrics.length < 6 || _historyData.length < 6) {
              _initializeHistoryData();
              _initializeHealthMetrics();
              _selectedMetricIndex = 0;
              return const Center(child: CircularProgressIndicator());
            }

            final data = dataSnapshot.data;
            final soil1 = _getDoubleValue(
              data?['soilMoisture1'],
              fallback: _plantData.soilMoisture,
            );
            final soil2 = _getDoubleValue(
              data?['soilMoisture2'],
              fallback: _plantData.soilMoisture,
            );
            final soil3 = _getDoubleValue(
              data?['soilMoisture3'],
              fallback: _plantData.soilMoisture,
            );
            final waterTemp = _getDoubleValue(
              data?['ntcTemperature'],
              fallback: _plantData.ntcTemperature,
            );

            _healthMetrics[0]['value'] = soil1;
            _healthMetrics[0]['status'] = _getStatusForMoisture(soil1.toInt());
            _appendHistory(0, soil1);

            _healthMetrics[1]['value'] = soil2;
            _healthMetrics[1]['status'] = _getStatusForMoisture(soil2.toInt());
            _appendHistory(1, soil2);

            _healthMetrics[2]['value'] = soil3;
            _healthMetrics[2]['status'] = _getStatusForMoisture(soil3.toInt());
            _appendHistory(2, soil3);

            _healthMetrics[3]['value'] = waterTemp;
            _healthMetrics[3]['status'] = _getStatusForTemperature(waterTemp);
            _appendHistory(3, waterTemp);

            return StreamBuilder<double>(
              // Listen to DHT temp changes
              stream: _plantData.dhtTemperatureStream,
              initialData: _plantData.dhtTemperature,
              builder: (context, dhtTempSnapshot) {
                if (dhtTempSnapshot.hasData) {
                  _healthMetrics[4]['value'] = dhtTempSnapshot.data!;
                  _healthMetrics[4]['status'] =
                      _getStatusForDhtTemperature(dhtTempSnapshot.data!);
                  _appendHistory(4, dhtTempSnapshot.data!);
                }

                return StreamBuilder<double>(
                  // Listen to humidity changes
                  stream: _plantData.humidityStream,
                  initialData: _plantData.humidity,
                  builder: (context, humiditySnapshot) {
                    if (humiditySnapshot.hasData) {
                      _healthMetrics[5]['value'] = humiditySnapshot.data!;
                      _healthMetrics[5]['status'] =
                          _getStatusForHumidity(humiditySnapshot.data!);
                      _appendHistory(5, humiditySnapshot.data!);
                    }

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall health status card
                            _buildOverallHealthCard(),
                            const SizedBox(height: 20),
                            // Health metrics grid
                            _buildHealthMetricsGrid(),
                            const SizedBox(height: 20),
                            // Historical data section
                            _buildHistoricalDataSection(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
    );
  }

  Widget _buildOverallHealthCard() {
    return StreamBuilder<String>(
      stream: _plantData.plantHealthStream,
      initialData: _plantData.plantHealth,
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;
        final textColor = colorScheme.onSurface;
        final subTextColor = textColor.withOpacity(0.82);
        final healthStatus = snapshot.data ?? 'UNKNOWN';
        // Calculate health percentage based on plant health status
        double healthPercentage = 0.0;
        switch (healthStatus) {
          case 'HEALTHY':
            healthPercentage = 0.95;
            break;
          case 'STRESSED':
            healthPercentage = 0.60;
            break;
          case 'NEEDS WATER':
            healthPercentage = 0.45;
            break;
          case 'OVERWATERED':
            healthPercentage = 0.30;
            break;
          default:
            healthPercentage = 0.50;
        }

        // Get health color based on plant health status
        Color healthColor = _getHealthColor(healthStatus);

        // Get health message based on plant health status
        String healthMessage = _getHealthMessage(healthStatus);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Health Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Circular indicator
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: healthPercentage,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade300,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(healthColor),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(healthPercentage * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: healthColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            healthStatus,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: healthColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            healthMessage,
                            style: TextStyle(
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: healthColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getHealthTip(healthStatus),
                          style: TextStyle(color: subTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to get health status color
  Color _getHealthColor(String status) {
    switch (status) {
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

  // Helper method to get health message
  String _getHealthMessage(String status) {
    switch (status) {
      case 'HEALTHY':
        return 'Your plant is doing well. Continue with the current care routine.';
      case 'STRESSED':
        return 'Your plant is experiencing stress. Check temperature and light conditions.';
      case 'NEEDS WATER':
        return 'Your plant needs watering soon. The soil is getting dry.';
      case 'OVERWATERED':
        return 'Your plant has too much water. Let the soil dry out before watering again.';
      default:
        return 'Unable to determine plant health status.';
    }
  }

  // Helper method to get health tip
  String _getHealthTip(String status) {
    switch (status) {
      case 'HEALTHY':
        return 'Consider adding a bit more fertilizer in the next 2-3 days to maintain optimal nutrient levels.';
      case 'STRESSED':
        return 'Move your plant to a more suitable location with moderate temperature and indirect sunlight.';
      case 'NEEDS WATER':
        return 'Water your plant thoroughly but avoid overwatering. Check soil moisture every few days.';
      case 'OVERWATERED':
        return 'Stop watering and ensure proper drainage. Check for root rot if condition persists.';
      default:
        return 'Monitor your plant regularly and adjust care as needed.';
    }
  }

  Widget _buildHealthMetricsGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _healthMetrics.length,
      itemBuilder: (context, index) {
        final metric = _healthMetrics[index];
        // Format the display value based on type
        String displayValue = '${metric['value']}${metric['unit']}';
        if (metric['value'] is double) {
          // Format double values to show only 1 decimal place
          double value = (metric['value'] as double);
          displayValue = '${value.toStringAsFixed(1)}${metric['unit']}';
        } else {
          displayValue = '${metric['value']}${metric['unit']}';
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMetricIndex = index;
            });
          },
          child: Card(
            elevation: _selectedMetricIndex == index ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedMetricIndex == index
                    ? metric['color']
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    metric['icon'],
                    color: metric['color'],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metric['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: metric['color'],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: metric['status'] == 'Good'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      metric['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: metric['status'] == 'Good'
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoricalDataSection() {
    return StreamBuilder<double>(
      stream: _plantData.temperatureStream,
      initialData: _plantData.temperature,
      builder: (context, waterTempSnapshot) {
        return StreamBuilder<double>(
          stream: _plantData.soilMoistureStream,
          initialData: _plantData.soilMoisture.toDouble(),
          builder: (context, moistureSnapshot) {
            return StreamBuilder<double>(
                stream: _plantData.dhtTemperatureStream,
                initialData: _plantData.dhtTemperature,
                builder: (context, dhtTempSnapshot) {
                  return StreamBuilder<double>(
                      stream: _plantData.humidityStream,
                      initialData: _plantData.humidity,
                      builder: (context, humiditySnapshot) {
                        final selectedMetric =
                            _healthMetrics[_selectedMetricIndex];
                        final historyData =
                            _historyData[_selectedMetricIndex].isEmpty
                                ? List<double>.filled(_historyLength, 0)
                                : _historyData[_selectedMetricIndex];

                        // Rest of the method remains unchanged
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ...existing code...
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${selectedMetric['name']} History',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white24
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Live',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Simple chart
                                SizedBox(
                                  height: 200,
                                  child: _buildSimpleLineChart(
                                      historyData, selectedMetric),
                                ),
                                const SizedBox(height: 16),

                                // Recommendations
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: selectedMetric['color']
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline,
                                          color: selectedMetric['color']),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          selectedMetric['recommendation'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Add refresh button to manually fetch history data
                                Center(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh History Data'),
                                    onPressed: () async {
                                      setState(() {
                                        _initializeHistoryData();
                                        for (int i = 0;
                                            i < _lastHistoryValues.length;
                                            i++) {
                                          _lastHistoryValues[i] = null;
                                        }
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Historical data refreshed'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      });
                });
          },
        );
      },
    );
  }

  Widget _buildSimpleLineChart(List<double> data, Map<String, dynamic> metric) {
    return CustomLineChart(
      data: data,
      labels: _lastSevenUpdates,
      unit: metric['unit'],
      lineColor: metric['color'],
    );
  }

  double _getDoubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
