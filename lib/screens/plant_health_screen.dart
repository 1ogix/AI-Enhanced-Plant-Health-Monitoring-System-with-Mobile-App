import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/plant_data.dart'; // Import the PlantData model

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  // Get instance of PlantData singleton
  final PlantData _plantData = PlantData();

  // Sample data for demonstration
  late List<Map<String, dynamic>> _healthMetrics;

  // History data for charts
  late List<List<double>> _historyData;

  // Dates for x-axis
  final List<String> _lastSevenDays = [
    '6 Days Ago',
    '5 Days Ago',
    '4 Days Ago',
    '3 Days Ago',
    '2 Days Ago',
    'Yesterday',
    'Today',
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

  // Initialize history data with values from PlantData when available
  void _initializeHistoryData() {
    _historyData = [
      // Soil moisture history (last 7 days)
      _plantData.soilMoistureHistory.isEmpty
          ? [50, 48, 52, 56, 54, 58, 56]
          : _plantData.soilMoistureHistory
              .map((value) => value.toDouble())
              .toList(),

      // Temperature history (last 7 days)
      _plantData.temperatureHistory.isEmpty
          ? [25, 24, 26, 27, 26, 25, 26]
          : _plantData.temperatureHistory,
    ];

    // Ensure each history list has at least 7 items for display
    for (int i = 0; i < _historyData.length; i++) {
      while (_historyData[i].length < 7) {
        if (i == 1) {
          // Temperature
          _historyData[i].insert(0, _plantData.temperature);
        } else if (i == 0) {
          // Soil moisture
          _historyData[i].insert(0, _plantData.soilMoisture.toDouble());
        }
      }

      // Trim lists to 7 items if they're longer
      if (_historyData[i].length > 7) {
        _historyData[i] = _historyData[i].sublist(_historyData[i].length - 7);
      }
    }
  }

  // Initialize health metrics with current plant data
  void _initializeHealthMetrics() {
    _healthMetrics = [
      {
        'name': 'Soil Moisture',
        'value': _plantData.soilMoisture,
        'unit': '%',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'recommendation': 'Optimal range: 40-60%',
        'status': _getStatusForMoisture(_plantData.soilMoisture),
      },
      {
        'name': 'Temperature',
        'value': _plantData.temperature,
        'unit': '°C',
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'recommendation': 'Optimal range: 20-28°C',
        'status': _getStatusForTemperature(_plantData.temperature),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Health Analysis'),
        backgroundColor: Colors.green.withOpacity(0.8),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<double>(
          // Listen to temperature changes
          stream: _plantData.temperatureStream,
          initialData: _plantData.temperature,
          builder: (context, tempSnapshot) {
            // Update temperature in health metrics when temperature changes
            if (tempSnapshot.hasData) {
              _healthMetrics[1]['value'] = tempSnapshot.data;
              _healthMetrics[1]['status'] =
                  _getStatusForTemperature(tempSnapshot.data!);
            }

            return StreamBuilder<int>(
                // Listen to moisture changes
                stream: _plantData.soilMoistureStream,
                initialData: _plantData.soilMoisture,
                builder: (context, moistureSnapshot) {
                  // Update soil moisture in health metrics when moisture changes
                  if (moistureSnapshot.hasData) {
                    _healthMetrics[0]['value'] = moistureSnapshot.data;
                    _healthMetrics[0]['status'] =
                        _getStatusForMoisture(moistureSnapshot.data!);
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
                });
          }),
    );
  }

  Widget _buildOverallHealthCard() {
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
                          value: 0.85,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      Center(
                        child: Text(
                          '85%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
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
                        'HEALTHY',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your plant is doing well. Continue with the current care routine.',
                        style: TextStyle(
                          color: Colors.black87,
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Consider adding a bit more fertilizer in the next 2-3 days to maintain optimal nutrient levels.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _healthMetrics.length,
      itemBuilder: (context, index) {
        final metric = _healthMetrics[index];
        // Format the display value based on type
        String displayValue;
        if (metric['name'] == 'Temperature') {
          // Format temperature to show only 1 decimal place
          double tempValue = (metric['value'] as double);
          displayValue = '${tempValue.toStringAsFixed(1)}${metric['unit']}';
        } else {
          // Keep original formatting for other metrics
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
    final selectedMetric = _healthMetrics[_selectedMetricIndex];

    // Update the temperature history data with latest temperature value
    if (_selectedMetricIndex == 1 &&
        _plantData.temperature != _historyData[1].last) {
      // Remove the oldest temperature value
      _historyData[1].removeAt(0);
      // Add the current temperature
      _historyData[1].add(_plantData.temperature);
    }

    // Update the soil moisture history data with latest moisture value
    if (_selectedMetricIndex == 0 &&
        _plantData.soilMoisture.toDouble() != _historyData[0].last) {
      // Remove the oldest moisture value
      _historyData[0].removeAt(0);
      // Add the current moisture
      _historyData[0].add(_plantData.soilMoisture.toDouble());
    }

    final historyData = _historyData[_selectedMetricIndex];

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedMetric['name']} History',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Last 7 Days',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Simple chart
            SizedBox(
              height: 200,
              child: _buildSimpleLineChart(historyData, selectedMetric),
            ),
            const SizedBox(height: 16),

            // Recommendations
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedMetric['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: selectedMetric['color']),
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

            // Analysis button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics),
                label: const Text('Detailed Analysis'),
                onPressed: () {
                  // Detailed analysis would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Detailed analysis coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: selectedMetric['color'],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLineChart(List<double> data, Map<String, dynamic> metric) {
    // Find min and max values for scaling
    final minValue = data.reduce(math.min);
    final maxValue = data.reduce(math.max);
    final range = maxValue - minValue;

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _ChartPainter(
        data: data,
        minValue: range > 0 ? minValue - (range * 0.1) : minValue * 0.9,
        maxValue: range > 0 ? maxValue + (range * 0.1) : maxValue * 1.1,
        lineColor: metric['color'],
        labels: _lastSevenDays,
        unit: metric['unit'],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final List<String> labels;
  final String unit;

  _ChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.labels,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final path = Path();
    final valueRange = maxValue - minValue;

    // Draw horizontal lines and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal grid lines
    for (int i = 0; i <= 3; i++) {
      final y = size.height - (size.height * (i / 3));
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );

      // Draw value labels
      final value = minValue + (valueRange * (i / 3));
      final text =
          value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
      textPainter.text = TextSpan(
        text: '$text$unit',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width - 5, y - textPainter.height / 2));
    }

    // Draw data points and lines
    for (int i = 0; i < data.length; i++) {
      final x = i * (size.width / (data.length - 1));
      final normalizedValue = (data[i] - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw data point
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      // Draw vertical grid lines
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, 0),
        linePaint,
      );

      // Draw x-axis labels on alternate points to avoid crowding
      if (data.length <= 7 || i % 2 == 0 || i == data.length - 1) {
        textPainter.text = TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 9,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            size.height + 5,
          ),
        );
      }

      // Draw value above dot
      textPainter.text = TextSpan(
        text: data[i]
            .toStringAsFixed(data[i].truncateToDouble() == data[i] ? 0 : 1),
        style: TextStyle(
          color: lineColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          y - 18,
        ),
      );
    }

    // Draw the line connecting all points
    canvas.drawPath(path, paint);

    // Create a gradient fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.3),
          lineColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
