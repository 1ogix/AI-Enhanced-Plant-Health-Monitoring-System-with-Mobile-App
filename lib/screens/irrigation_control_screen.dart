import 'package:flutter/material.dart';
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
  bool _isAutoMode = true; // Default to auto mode

  // Time settings for manual mode
  int _hours = 0; // Added hours
  int _minutes = 0;
  int _seconds = 0;
  // Removed the selected days variables and map

  bool _isSaving = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadIrrigationSettings();
  }

  Future<void> _loadIrrigationSettings() async {
    try {
      final settings = await _dbService.getIrrigationSettings();
      if (settings != null) {
        setState(() {
          _isAutoMode = settings['isAutoMode'] ?? true;
          _hours = settings['hours'] ?? 0;
          _minutes = settings['minutes'] ?? 0;
          _seconds = settings['seconds'] ?? 0;
          // Removed loading selected days
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading settings: $e';
      });
    }
  }

  Future<void> _saveIrrigationSettings() async {
    setState(() {
      _isSaving = true;
      _statusMessage = '';
    });

    try {
      // Removed updating selected days from weekdays map
      final settings = {
        'isAutoMode': _isAutoMode,
        'hours': _hours,
        'minutes': _minutes,
        'seconds': _seconds,
        // Removed selectedDays
      };

      await _dbService.saveIrrigationSettings(settings);

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
              // Irrigation Control title and mode selection
              Card(
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
                      const Text(
                        'Irrigation Control',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeButton('Auto', _isAutoMode, () {
                              setState(() {
                                _isAutoMode = true;
                              });
                            }),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModeButton('Manual', !_isAutoMode, () {
                              setState(() {
                                _isAutoMode = false;
                              });
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isAutoMode
                            ? 'System will water the plant automatically when needed.'
                            : 'Set your own watering schedule.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Manual irrigation settings (only shown in manual mode)
              if (!_isAutoMode) ...[
                Card(
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
                        const Text(
                          'Watering Duration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Every:',
                                style: TextStyle(fontSize: 14)),
                            const Spacer(),
                            // Hours input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Hours',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 80,
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
                                        text: _hours.toString()),
                                    onChanged: (value) {
                                      setState(() {
                                        _hours = int.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Minutes input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Minutes',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 80,
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
                                        text: _minutes.toString()),
                                    onChanged: (value) {
                                      setState(() {
                                        _minutes = int.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Seconds input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Seconds',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 80,
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
                                        text: _seconds.toString()),
                                    onChanged: (value) {
                                      setState(() {
                                        _seconds = int.tryParse(value) ?? 0;
                                      });
                                    },
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

                const SizedBox(height: 16),

                // "Select Days" Card section removed
              ],

              const SizedBox(height: 24),

              // Save button
              Center(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveIrrigationSettings,
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
}
