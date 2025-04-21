import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/plant_health_screen.dart';
// import 'screens/developer_tools_screen.dart';
// import 'screens/irrigation_screen.dart';
// import 'screens/settings_screen.dart';
// import 'screens/logs_screen.dart';
import 'widgets/sidebar.dart';

void main() {
  runApp(const PlantMonitorApp());
}

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
    const SizedBox(child: Center(child: Text('Settings Screen'))),
    const SizedBox(child: Center(child: Text('Logs Screen'))),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          _screens[_selectedIndex],

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
