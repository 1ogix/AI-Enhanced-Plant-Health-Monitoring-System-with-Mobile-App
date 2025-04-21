import 'package:flutter/material.dart';
import 'dart:math' as math;

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  // Sample data for demonstration
  final List<Map<String, dynamic>> _healthMetrics = [
    {
      'name': 'Soil Moisture',
      'value': 56,
      'unit': '%',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'recommendation': 'Optimal range: 40-60%',
      'status': 'Good',
    },
    {
      'name': 'Temperature',
      'value': 26.0,
      'unit': '°C',
      'icon': Icons.thermostat,
      'color': Colors.orange,
      'recommendation': 'Optimal range: 20-28°C',
      'status': 'Good',
    },
    {
      'name': 'Light Exposure',
      'value': 78,
      'unit': '%',
      'icon': Icons.wb_sunny,
      'color': Colors.amber,
      'recommendation': 'Optimal range: 60-80%',
      'status': 'Good',
    },
    {
      'name': 'Soil pH',
      'value': 6.5,
      'unit': 'pH',
      'icon': Icons.science,
      'color': Colors.purple,
      'recommendation': 'Optimal range: 6.0-7.0',
      'status': 'Good',
    },
    {
      'name': 'Nutrient Level',
      'value': 42,
      'unit': '%',
      'icon': Icons.spa,
      'color': Colors.green,
      'recommendation': 'Consider adding fertilizer soon',
      'status': 'Moderate',
    },
  ];

  // History data for charts
  final List<List<double>> _historyData = [
    // Soil moisture history (last 7 days)
    [50, 48, 52, 56, 54, 58, 56],
    // Temperature history (last 7 days)
    [25, 24, 26, 27, 26, 25, 26],
    // Light exposure history (last 7 days)
    [70, 75, 68, 72, 80, 78, 78],
    // pH history (last 7 days)
    [6.4, 6.4, 6.5, 6.6, 6.5, 6.5, 6.5],
    // Nutrient level history (last 7 days)
    [48, 46, 45, 44, 43, 42, 42],
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Health Analysis'),
        backgroundColor: Colors.green.withOpacity(0.8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
      ),
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
                    '${metric['value']}${metric['unit']}',
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
