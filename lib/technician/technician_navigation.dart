import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/socket_service.dart';
import 'technician_tasks_screen.dart';
import 'technician_profile_screen.dart';

class TechnicianNavigation extends StatefulWidget {
  const TechnicianNavigation({super.key});

  @override
  State<TechnicianNavigation> createState() => _TechnicianNavigationState();
}

class _TechnicianNavigationState extends State<TechnicianNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TechnicianTasksScreen(),
    TechnicianProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _joinTechnicianRoom();
  }

  Future<void> _joinTechnicianRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    if (userId > 0) {
      // Join room teknisi agar bisa terima notifikasi assignment real-time
      SocketService().joinTechnicianRoom(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFF1B5E20).withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Color(0xFF1B5E20)),
            label: 'Tugas Saya',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
