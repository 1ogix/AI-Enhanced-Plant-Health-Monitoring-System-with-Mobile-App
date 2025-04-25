import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/plant_health_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/logs_screen.dart'; // Add import for LogsScreen
import 'widgets/sidebar.dart';
import 'services/firebase_config.dart';
import 'services/esp32_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with graceful error handling
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.platformOptions,
    );

    // Request permissions
    await _requestPermissions();

    runApp(const PlantMonitorApp());
  } catch (e) {
    print('Firebase initialization error: $e');
    // Run app in configuration error mode
    runApp(const PlantMonitorConfigErrorApp());
  }
}

// Request necessary permissions for the app
Future<void> _requestPermissions() async {
  // Request permissions required for connecting to ESP32 and sensors
  await [
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.location,
    Permission.locationWhenInUse,
    Permission.storage,
  ].request();

  // Log the status of permissions
  debugPrint('Bluetooth: ${await Permission.bluetooth.status}');
  debugPrint('Bluetooth Connect: ${await Permission.bluetoothConnect.status}');
  debugPrint('Bluetooth Scan: ${await Permission.bluetoothScan.status}');
  debugPrint('Location: ${await Permission.location.status}');
  debugPrint(
      'Location When In Use: ${await Permission.locationWhenInUse.status}');
  debugPrint('Storage: ${await Permission.storage.status}');
}

// Main app when Firebase is properly configured
class PlantMonitorApp extends StatelessWidget {
  const PlantMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// Fallback app shown when Firebase configuration is missing or invalid
class PlantMonitorConfigErrorApp extends StatelessWidget {
  const PlantMonitorConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitor - Configuration Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Configuration Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Firebase Configuration Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Please follow these steps to configure Firebase:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('1. Copy the template configuration file:'),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'lib/services/firebase_config_template.dart → lib/services/firebase_config.dart',
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                          '2. Edit the new file with your Firebase project details'),
                      SizedBox(height: 10),
                      Text('3. Restart the application'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main screen with sidebar and content
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  // Add animation controller
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlantHealthScreen(),
    // You'll need to create these screens
    // const SizedBox(child: Center(child: Text('Plant Health Screen'))),
    const SizedBox(child: Center(child: Text('Developer Tools Screen'))),
    const SizedBox(child: Center(child: Text('Irrigation Screen'))),
    const SettingsScreen(),
    const LogsScreen(), // Update to use the new LogsScreen
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Create sidebar animation
    _sidebarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start ESP32 connection monitoring
    ESP32Service().startConnectionMonitoring();
  }

  @override
  void dispose() {
    _animationController.dispose();
    ESP32Service().stopConnectionMonitoring();
    super.dispose();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content - always full width
          Column(
            children: [
              // ESP32 connection status banner
              // const ESP32ConnectionStatusWidget(showDetailedError: true), //No ESP32 widget for now

              // Content area
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),

          // Sidebar overlay with animation
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Positioned(
                left: -200 * (1 - _sidebarAnimation.value),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.2 * _sidebarAnimation.value),
                        blurRadius: 5,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Sidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      _onItemSelected(index);
                      // Optionally close sidebar on mobile when item selected
                      if (MediaQuery.of(context).size.width < 600) {
                        _toggleSidebar();
                      }
                    },
                  ),
                ),
              );
            },
          ),

          // Floating action button for sidebar toggle
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _toggleSidebar,
              tooltip: _isSidebarOpen ? 'Close Sidebar' : 'Open Sidebar',
              mini: false,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _animationController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
