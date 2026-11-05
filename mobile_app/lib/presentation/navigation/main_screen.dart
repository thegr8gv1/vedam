import 'package:flutter/material.dart';
import '../../core/services/audio_service.dart';
import '../../data/repositories/mantra_repository.dart';
import '../../data/repositories/scripture_repository.dart';
import '../../state/app_state.dart';
import '../../state/audio_state.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/mantras/mantras_screen.dart';
import '../screens/sadhana/sadhana_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../../data/repositories/panchangam_repository.dart';
import '../../state/panchangam_state.dart';
import '../../state/vrat_state.dart';
import '../screens/panchangam/panchangam_screen.dart';

class MainScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final PanchangamRepository? panchangamRepository;
  final PanchangamState? panchangamState;
  final VratState? vratState;
  final AppState appState;
  final int initialIndex;

  const MainScreen({
    super.key,
    required this.repository,
    this.mantraRepository,
    this.audioState,
    this.panchangamRepository,
    this.panchangamState,
    this.vratState,
    required this.appState,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final MantraRepository _mantraRepository;
  late final AudioState _audioState;
  late final PanchangamRepository _panchangamRepository;
  late final PanchangamState _panchangamState;
  late final VratState _vratState;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _mantraRepository = widget.mantraRepository ?? MantraRepositoryImpl();
    _audioState = widget.audioState ??
        AudioState(audioService: AudioPlaybackServiceImpl());
    _panchangamRepository = widget.panchangamRepository ?? PanchangamRepositoryImpl();
    _panchangamState = widget.panchangamState ??
        PanchangamState(repository: _panchangamRepository);
    _vratState = widget.vratState ?? VratState();
  }

  void _openPanchangamScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanchangamScreen(
          state: _panchangamState,
          repository: _panchangamRepository,
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openMantrasScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MantrasScreen(
          repository: _mantraRepository,
          audioState: _audioState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        repository: widget.repository,
        appState: widget.appState,
        onNavigateToTab: _onTabSelected,
        onOpenMantras: _openMantrasScreen,
        onOpenPanchangam: _openPanchangamScreen,
        panchangamState: _panchangamState,
      ),
      LibraryScreen(
        repository: widget.repository,
        appState: widget.appState,
      ),
      SadhanaScreen(
        appState: widget.appState,
        mantraRepository: _mantraRepository,
        audioState: _audioState,
        panchangamState: _panchangamState,
        vratState: _vratState,
        onOpenMantras: _openMantrasScreen,
        onOpenPanchangam: _openPanchangamScreen,
        onOpenLibrary: () => _onTabSelected(1),
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
