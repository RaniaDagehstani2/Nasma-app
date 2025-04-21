import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int, String, String) onItemTapped; // Now takes both IDs
  final String patientId;
  final String userId; // Newly added

  AppFooter({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.patientId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: selectedIndex,
      onTap: (index) {
        onItemTapped(index, patientId, userId); // Pass both IDs on tap
      },
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/home.png', width: 24, height: 24),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/device.png', width: 30, height: 30),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/user.png', width: 24, height: 24),
          label: '',
        ),
      ],
    );
  }
}
