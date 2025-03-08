import 'package:flutter/material.dart';
//import 'personalInfo.dart';
import 'homepage.dart';
import 'connect_patch_screen.dart';

class AppFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int, String) onItemTapped; // Accepts patientId
  final String patientId; // Store patientId

  AppFooter({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: selectedIndex,
      onTap: (index) {
        onItemTapped(index, patientId); // Pass patientId when a tab is tapped
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
