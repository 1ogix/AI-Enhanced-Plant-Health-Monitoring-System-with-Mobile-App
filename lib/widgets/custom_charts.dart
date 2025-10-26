import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final String unit;
  final Color lineColor;
  final double height;

  const CustomLineChart({
    super.key,
    required this.data,
    required this.labels,
    required this.unit,
    required this.lineColor,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    // Find min and max values for scaling
    final minValue = data.isNotEmpty ? data.reduce(math.min) : 0.0;
    final maxValue = data.isNotEmpty ? data.reduce(math.max) : 1.0;
    final range = maxValue - minValue;

    return SizedBox(
      height: height,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 35, bottom: 20, right: 10, top: 20),
        child: CustomPaint(
          size: Size.infinite,
          painter: ChartPainter(
            data: data,
            minValue: range > 0 ? minValue - (range * 0.1) : minValue * 0.9,
            maxValue: range > 0 ? maxValue + (range * 0.1) : maxValue * 1.1,
            lineColor: lineColor,
            labels: labels,
            unit: unit,
          ),
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final List<String> labels;
  final String unit;

  ChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.labels,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Don't paint if data is empty
    if (data.isEmpty) return;

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
    var valueRange = maxValue - minValue;

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

      // Draw value labels. Handle case where valueRange is 0.
      if (valueRange == 0 && i == 0) {
        // If range is 0, only draw one label for the single value
        valueRange = 1; // prevent further division by zero
      }
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

      // Prevent division by zero if all values are the same
      final normalizedValue =
          valueRange > 0 ? (data[i] - minValue) / valueRange : 0.5;

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
          text: i < labels.length ? labels[i] : '',
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

// Circular gauge widget for displaying metrics like temperature
class CircularGauge extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String label;
  final String unit;
  final Color color;
  final double size;

  const CircularGauge({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.unit,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage
    final percentage =
        ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size * 0.7,
                height: size * 0.7,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(
                        value.truncateToDouble() == value ? 0 : 1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
