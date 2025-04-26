import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import '../models/plant_data.dart';
import '../services/firebase_db_service.dart';

class LogsScreen extends StatefulWidget {
  final bool isFirebaseInitialized;

  const LogsScreen({Key? key, this.isFirebaseInitialized = false})
      : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final FirebaseDbService _dbService = FirebaseDbService();
  // final PlantData _plantData = PlantData();

  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Format for timestamps
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy - hh:mm:ss a');

  // Alternative format options we can choose from:
  // For date+time: DateFormat('MMM d, yyyy - HH:mm:ss');
  // For date+time with day name: DateFormat('EEE, MMM d - HH:mm');
  // For 12-hour format: DateFormat('hh:mm:ss a');

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  // Fetch historical data from Firebase
  Future<void> _fetchHistoricalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get more historical entries (20 instead of just 7)
      final data = await _dbService.getHistoricalData(20);

      if (data.isEmpty) {
        _errorMessage = 'No historical data found';
      }

      // Sort data by timestamp in descending order (most recent first)
      data.sort((a, b) {
        final timestampA = a['timestamp'] as int? ?? 0;
        final timestampB = b['timestamp'] as int? ?? 0;
        return timestampB.compareTo(timestampA); // Descending order
      });

      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading logs: $e';
        _isLoading = false;
      });
    }
  }

  // Convert Unix timestamp to readable date
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      // Convert from seconds to milliseconds by multiplying by 1000
      // This is necessary because ESP32 stores timestamps in seconds, not milliseconds
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return _dateFormat.format(dateTime);
    }
    return 'Invalid timestamp';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistoricalData,
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLogContent(),
    );
  }

  Widget _buildLogContent() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchHistoricalData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_historyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No log entries found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing ${_historyData.length} log entries. Pull down to refresh.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchHistoricalData,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _historyData.length,
              itemBuilder: (context, index) {
                final data = _historyData[index];
                final timestamp = data['timestamp'];

                // Get plant health status
                String plantHealth =
                    data['plantHealth'] as String? ?? 'Unknown';

                // Determine card color based on plant health
                Color cardColor;
                switch (plantHealth) {
                  case 'HEALTHY':
                    cardColor = Colors.green.shade50;
                    break;
                  case 'NEEDS WATER':
                    cardColor = Colors.blue.shade50;
                    break;
                  case 'OVERWATERED':
                    cardColor = Colors.indigo.shade50;
                    break;
                  case 'STRESSED':
                    cardColor = Colors.orange.shade50;
                    break;
                  default:
                    cardColor = Colors.grey.shade50;
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: cardColor,
                  elevation: 2,
                  child: ExpansionTile(
                    leading: _getIconForHealth(plantHealth),
                    title: Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: $plantHealth',
                      style: TextStyle(
                        color: _getColorForHealth(plantHealth),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDataRow(
                              'Temperature',
                              data['temperature']?.toString() ?? 'N/A',
                              '°C',
                              Icons.thermostat,
                              Colors.red,
                            ),
                            const Divider(),
                            _buildDataRow(
                              'Soil Moisture',
                              data['soilMoisture']?.toString() ?? 'N/A',
                              '%',
                              Icons.water_drop,
                              Colors.blue,
                            ),
                            const Divider(),
                            _buildDataRow(
                              'Light Exposure',
                              data['lightExposure']?.toString() ?? 'N/A',
                              '%',
                              Icons.wb_sunny,
                              Colors.amber,
                            ),
                            const Divider(),
                            _buildDataRow(
                              'Soil pH',
                              data['soilPh']?.toString() ?? 'N/A',
                              '',
                              Icons.science,
                              Colors.purple,
                            ),
                            const Divider(),
                            _buildDataRow(
                              'Nutrient Level',
                              data['nutrientLevel']?.toString() ?? 'N/A',
                              '%',
                              Icons.grass,
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
      String label, String value, String unit, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '$value $unit',
          style: TextStyle(color: Colors.grey[800]),
        ),
      ],
    );
  }

  Icon _getIconForHealth(String health) {
    switch (health) {
      case 'HEALTHY':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'NEEDS WATER':
        return const Icon(Icons.water_drop, color: Colors.blue);
      case 'OVERWATERED':
        return const Icon(Icons.warning, color: Colors.indigo);
      case 'STRESSED':
        return const Icon(Icons.warning_amber, color: Colors.orange);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  Color _getColorForHealth(String health) {
    switch (health) {
      case 'HEALTHY':
        return Colors.green;
      case 'NEEDS WATER':
        return Colors.blue;
      case 'OVERWATERED':
        return Colors.indigo;
      case 'STRESSED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
