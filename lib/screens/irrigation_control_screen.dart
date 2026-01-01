import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_db_service.dart';

class IrrigationControlScreen extends StatefulWidget {
  final bool isFirebaseInitialized;

  const IrrigationControlScreen(
      {super.key, this.isFirebaseInitialized = false});

  @override
  State<IrrigationControlScreen> createState() =>
      _IrrigationControlScreenState();
}

class _IrrigationControlScreenState extends State<IrrigationControlScreen> {
  final FirebaseDbService _dbService = FirebaseDbService();
  static const int _pumpCount = 3;
  final List<bool> _isAutoMode = List<bool>.filled(_pumpCount, true);
  final List<int> _minutes = List<int>.filled(_pumpCount, 0);
  final List<int> _seconds = List<int>.filled(_pumpCount, 0);

  bool _isSaving = false;
  bool _isTriggeringAll = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPumpConfigs();
  }

  Future<void> _loadPumpConfigs() async {
    try {
      await _dbService.initialize();
      if (!widget.isFirebaseInitialized) return;

      final ref = FirebaseDatabase.instance.ref('plantData/manualPumpConfigs');
      final snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value is! Map) return;
      final data = snapshot.value as Map<Object?, Object?>;

      setState(() {
        for (int i = 0; i < _pumpCount; i++) {
          final pumpKey = 'pump${i + 1}';
          final raw = data[pumpKey];
          if (raw is Map) {
            final pump = raw.cast<Object?, Object?>();
            _isAutoMode[i] = (pump['isAutoMode'] as bool?) ?? true;
            _minutes[i] = _getIntValue(pump['minutes']);
            _seconds[i] = _getIntValue(pump['seconds']);
          }
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading settings: $e';
      });
    }
  }

  Future<void> _savePumpConfigs() async {
    setState(() {
      _isSaving = true;
      _statusMessage = '';
    });

    try {
      await _dbService.initialize();
      if (!widget.isFirebaseInitialized) return;

      final baseRef =
          FirebaseDatabase.instance.ref('plantData/manualPumpConfigs');
      final updates = <Future<void>>[];
      for (int i = 0; i < _pumpCount; i++) {
        final pumpRef = baseRef.child('pump${i + 1}');
        updates.add(pumpRef.update({
          'isAutoMode': _isAutoMode[i],
          'minutes': _minutes[i],
          'seconds': _seconds[i],
        }));
      }
      await Future.wait(updates);

      setState(() {
        _statusMessage = 'Settings saved successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving settings: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _triggerPump(int index) async {
    setState(() {
      _statusMessage = '';
    });

    try {
      await _dbService.initialize();
      if (!widget.isFirebaseInitialized) return;

      final pumpRef = FirebaseDatabase.instance
          .ref('plantData/manualPumpConfigs/pump${index + 1}');
      await pumpRef.update({
        'isAutoMode': _isAutoMode[index],
        'minutes': _minutes[index],
        'seconds': _seconds[index],
        'manualTrigger': true,
      });
      setState(() {
        _statusMessage = 'Pump ${index + 1} triggered';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error triggering pump ${index + 1}: $e';
      });
    }
  }

  Future<void> _triggerAllPumps() async {
    setState(() {
      _isTriggeringAll = true;
      _statusMessage = '';
    });

    try {
      await _dbService.initialize();
      if (!widget.isFirebaseInitialized) return;

      final baseRef =
          FirebaseDatabase.instance.ref('plantData/manualPumpConfigs');
      final updates = <Future<void>>[];
      for (int i = 0; i < _pumpCount; i++) {
        updates.add(
          baseRef.child('pump${i + 1}').update({'manualTrigger': true}),
        );
      }
      await Future.wait(updates);

      setState(() {
        _statusMessage = 'All pumps triggered';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error triggering all pumps: $e';
      });
    } finally {
      setState(() {
        _isTriggeringAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Control'),
        backgroundColor: Colors.green.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView to handle overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _pumpCount; i++) ...[
                _buildPumpCard(i),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // Save button
              Center(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePumpConfigs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(200, 45),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Settings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: _isTriggeringAll ? null : _triggerAllPumps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(200, 45),
                  ),
                  child: _isTriggeringAll
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Start Pump All',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('Error')
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Add padding at the bottom to ensure everything is visible
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPumpCard(int index) {
    final pumpNumber = index + 1;
    final isAuto = _isAutoMode[index];
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pump $pumpNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModeButton('Auto', isAuto, () {
                    setState(() {
                      _isAutoMode[index] = true;
                    });
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModeButton('Manual', !isAuto, () {
                    setState(() {
                      _isAutoMode[index] = false;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isAuto
                  ? 'System will water this pump automatically when needed.'
                  : 'Set the manual watering duration for this pump.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            if (!isAuto)
              Row(
                children: [
                  const Text('Duration:', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Minutes', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        height: 48,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          textAlign: TextAlign.center,
                          controller: TextEditingController(
                              text: _minutes[index].toString()),
                          onChanged: (value) {
                            setState(() {
                              _minutes[index] = int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Seconds', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        height: 48,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          textAlign: TextAlign.center,
                          controller: TextEditingController(
                              text: _seconds[index].toString()),
                          onChanged: (value) {
                            setState(() {
                              _seconds[index] = int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _triggerPump(index),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Pump'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getIntValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
