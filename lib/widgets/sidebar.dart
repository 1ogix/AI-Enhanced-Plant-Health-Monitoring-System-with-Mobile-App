import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50), // Space at the top
        _buildNavItem(0, 'Home Page', Icons.home),
        _buildNavItem(1, 'Plant Health Analysis', Icons.eco),
        _buildNavItem(2, 'Irrigation Control', Icons.water_drop),
        _buildNavItem(3, 'Settings', Icons.settings),
        _buildNavItem(4, 'Logs', Icons.list_alt),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text(
            'Plant Monitor',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.grey.shade600,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () => onItemSelected(index),
      tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
    );
  }
}
