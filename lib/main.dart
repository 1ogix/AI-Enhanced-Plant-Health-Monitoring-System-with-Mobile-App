import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/plant_health_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/irrigation_control_screen.dart';
import 'widgets/sidebar.dart';
import 'services/firebase_config.dart';
import 'services/esp32_service.dart';
import 'services/firebase_db_service.dart';
import 'services/firebase_auth_service.dart';

// Global logger for debugging
void log(String message) {
  // ignore: avoid_print
  print('[PlantApp] $message');
}

// Flag to track if Firebase is fully initialized
bool isFirebaseInitialized = false;

void main() async {
  // Wrap the entire app initialization in a zone to catch errors
  runZonedGuarded(() async {
    try {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();
      log('Flutter initialized');

      // Initialize Firebase with graceful error handling
      try {
        log('Attempting to initialize Firebase...');
        await Firebase.initializeApp();
        log('Firebase initialized successfully');

        // Check if Firebase was actually initialized
        final apps = Firebase.apps;
        log('Firebase apps initialized: ${apps.length}');

        if (apps.isNotEmpty) {
          isFirebaseInitialized = true;

          // Initialize Firebase services
          try {
            log('Initializing Firebase Database Service...');
            await FirebaseDbService().initialize();
            log('Firebase Database Service initialized successfully');

            log('Initializing Firebase Auth Service...');
            await FirebaseAuthService().initialize();
            log('Firebase Auth Service initialized successfully');
          } catch (e) {
            log('Error initializing Firebase services: $e');
          }
        } else {
          log('Firebase initialization appeared to succeed but no apps were registered');
          isFirebaseInitialized = false;
        }
      } catch (e) {
        log('Firebase initialization error: $e');
        isFirebaseInitialized = false;
      }

      // Request permissions
      await _requestPermissions();

      // Run the app, passing the Firebase initialization status
      runApp(PlantMonitorApp(isFirebaseInitialized: isFirebaseInitialized));
    } catch (e, stack) {
      log('Error during app initialization: $e');
      log('Stack trace: $stack');
      // Still try to run the app with Firebase status
      runApp(const PlantMonitorApp(isFirebaseInitialized: false));
    }
  }, (error, stack) {
    // This catches any errors not caught by the try/catch
    log('Uncaught error: $error');
    log('Stack trace: $stack');
  });
}

// Request necessary permissions for the app
Future<void> _requestPermissions() async {
  try {
    // First check if we're running on an emulator/simulator
    bool isRealDevice = true;
    if (Platform.isIOS) {
      // Simple heuristic - most simulators use specific deviceModel strings
      final deviceModel = Platform.operatingSystemVersion;
      if (deviceModel.toLowerCase().contains('simulator')) {
        isRealDevice = false;
      }
    }

    // Only request certain permissions on real devices
    final permissionsToRequest = <Permission>[];

    // Always request these
    permissionsToRequest.addAll([
      Permission.storage,
    ]);

    // Only on real devices request these
    if (isRealDevice) {
      permissionsToRequest.addAll([
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ]);
    }

    // Request the permissions
    if (permissionsToRequest.isNotEmpty) {
      log('Requesting permissions: $permissionsToRequest');
      for (var permission in permissionsToRequest) {
        var status = await permission.request();
        log('Permission status for $permission: $status');
      }
    }
  } catch (e) {
    log('Error requesting permissions: $e');
    // Don't rethrow - just log the error
  }
}

// Main app
class PlantMonitorApp extends StatelessWidget {
  final bool isFirebaseInitialized;

  const PlantMonitorApp({super.key, required this.isFirebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MainScreen(isFirebaseInitialized: isFirebaseInitialized),
    );
  }
}

// Main screen with sidebar and content
class MainScreen extends StatefulWidget {
  final bool isFirebaseInitialized;

  const MainScreen({super.key, required this.isFirebaseInitialized});

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

  late List<Widget> _screens;

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

    // Delay ESP32 connection monitoring to prevent startup crashes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Only start if widget is still mounted
        try {
          ESP32Service().startConnectionMonitoring();
          log('ESP32 service started');
        } catch (e) {
          log('Error starting ESP32 service: $e');
        }
      }
    });

    // Update screen list with Firebase initialization status
    _updateScreens();
  }

  // Update screens with Firebase status
  void _updateScreens() {
    setState(() {
      _screens = [
        HomeScreen(isFirebaseInitialized: widget.isFirebaseInitialized),
        PlantHealthScreen(isFirebaseInitialized: widget.isFirebaseInitialized),
        IrrigationControlScreen(
            isFirebaseInitialized: widget.isFirebaseInitialized),
        SettingsScreen(isFirebaseInitialized: widget.isFirebaseInitialized),
        LogsScreen(isFirebaseInitialized: widget.isFirebaseInitialized),
      ];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_isSidebarOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_isSidebarOpen) {
      _toggleSidebar(); // Close sidebar after selection on mobile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Watering System'),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleSidebar,
        ),
      ),
      body: Stack(
        children: [
          // Main content
          _screens[_selectedIndex],

          // Semi-transparent overlay when sidebar is open
          if (_isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),

          // Animated sidebar (now as the last child so it's on top)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned(
                left: -250 * (1 - _sidebarAnimation.value),
                top: 0,
                bottom: 0,
                width: 250,
                child: Material(
                  elevation: 8.0,
                  child: Sidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemSelected,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
