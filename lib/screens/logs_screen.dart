import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_db_service.dart';

class LogsScreen extends StatefulWidget {
  final bool isFirebaseInitialized;

  const LogsScreen({super.key, this.isFirebaseInitialized = false});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final FirebaseDbService _dbService = FirebaseDbService();

  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy - hh:mm:ss a');

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  Future<void> _fetchHistoricalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _dbService.getHistoricalData(20);
      if (data.isEmpty) _errorMessage = 'No historical data found';
      data.sort((a, b) => ((b['timestamp'] ?? 0) as int)
          .compareTo((a['timestamp'] ?? 0) as int));
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return _dateFormat.format(dateTime);
    }
    return 'Invalid timestamp';
  }

  // ────────────────────────────────────────────────────────────────
  // 🧩 NEW: Fetch AI Analysis History
  List<Map<String, dynamic>> _analysisLogs = [];
  bool _loadingAnalysis = false;

  Future<void> _fetchAnalysisHistory() async {
    setState(() => _loadingAnalysis = true);
    try {
      final db = FirebaseDatabase.instance.ref('plantData/analysis');
      final snap = await db.get();

      if (snap.exists && snap.value is Map) {
        final data = snap.value as Map;
        _analysisLogs = data.entries.map<Map<String, dynamic>>((entry) {
          final v = entry.value as Map;
          return {
            'key': entry.key,
            'status': v['status'] ?? 'Unknown',
            'updated': v['updated'],
            'image': v['image'],
          };
        }).toList()
          ..sort((a, b) =>
              (b['updated'] ?? 0).compareTo(a['updated'] ?? 0)); // newest first
      } else {
        _analysisLogs = [];
      }
    } catch (e) {
      _analysisLogs = [];
    }
    setState(() => _loadingAnalysis = false);
  }
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('System Logs'),
          backgroundColor: Colors.lightGreen,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: Colors.green[100],
              child: const TabBar(
                indicatorColor: Colors.green,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                tabs: [
                  Tab(text: 'Data Logs'),
                  Tab(text: 'AI Analysis History'),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _fetchHistoricalData();
                _fetchAnalysisHistory();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ───── Tab 1: your existing Logs UI ─────
            _buildDataLogs(),
            // ───── Tab 2: new AI Analysis History ─────
            _buildAnalysisHistory(),
          ],
        ),
      ),
    );
  }

  // ⬇ ORIGINAL CODE wrapped into a method (unchanged)
  Widget _buildDataLogs() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                String plantHealth =
                    data['plantHealth'] as String? ?? 'Unknown';
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

  // ⬇ NEW TAB content: AI Analysis History
  Widget _buildAnalysisHistory() {
    if (_loadingAnalysis) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analysisLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 12),
            Text('No AI analysis history found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _analysisLogs.length,
      itemBuilder: (context, i) {
        final item = _analysisLogs[i];
        final status = item['status'] ?? 'Unknown';
        final updated = item['updated'] ?? 0;
        final imageB64 = item['image'];

        final isHealthy = status.toLowerCase().contains('healthy') &&
            !status.toLowerCase().contains('unhealthy');

        return Card(
          margin: const EdgeInsets.all(8),
          color: isHealthy ? Colors.green[50] : Colors.yellow[50],
          child: ListTile(
            leading: imageB64 != null && imageB64.toString().isNotEmpty
                ? Image.memory(
                    base64Decode(imageB64),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported, size: 40),
            title: Text(status),
            subtitle: Text(
              updated == 0
                  ? 'No timestamp'
                  : 'Updated: ${DateTime.fromMillisecondsSinceEpoch(updated)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(
      String label, String value, String unit, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('$value $unit', style: TextStyle(color: Colors.grey[800])),
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
