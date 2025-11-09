import 'package:flutter/material.dart';
import 'home/browse_listings_screen.dart';
import 'home/my_listings_screen.dart';
import 'home/chats_screen.dart';
import 'settings/settings_screen.dart';
import 'swap_requests_screen.dart'; // ADD THIS IMPORT

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BrowseListingsScreen(),
    MyListingsScreen(),
    SwapRequestsScreen(), // ADD THIS SCREEN
    ChatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2D3142),
        selectedItemColor: const Color(0xFFF5C842),
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz), // SWAP ICON
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
