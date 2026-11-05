import 'package:flutter/material.dart';
import '../../data/repositories/scripture_repository.dart';
import '../../state/app_state.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/sadhana/sadhana_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final int initialIndex;

  const MainScreen({
    super.key,
    required this.repository,
    required this.appState,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        repository: widget.repository,
        appState: widget.appState,
        onNavigateToTab: _onTabSelected,
      ),
      LibraryScreen(
        repository: widget.repository,
        appState: widget.appState,
      ),
      SadhanaScreen(
        appState: widget.appState,
      ),
      FavoritesScreen(
        repository: widget.repository,
        appState: widget.appState,
        onNavigateToTab: _onTabSelected,
      ),
      SettingsScreen(
        appState: widget.appState,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.temple_hindu_outlined),
            activeIcon: Icon(Icons.temple_hindu),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_outlined),
            activeIcon: Icon(Icons.self_improvement),
            label: 'Sadhana',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
