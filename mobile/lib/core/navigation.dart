import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/home/home_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/intelligence/intelligence_screen.dart';
import '../features/simulate/simulate_screen.dart';
import '../features/settings/settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Portfolio Climate Risk',
    'Explore & Dependencies',
    'Climate Intelligence',
    'Scenario Simulation',
  ];

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onExploreGraph: () => _navigateToTab(1),
        onInvestigate: () => _navigateToTab(2),
        onSimulate: () => _navigateToTab(3),
      ),
      const ExploreScreen(),
      const IntelligenceScreen(),
      const SimulateScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24, color: ClimatwinTheme.darkGreenPrimary),
            tooltip: 'Profile & Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Exactly four primary bottom navigation destinations
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            activeIcon: Icon(Icons.auto_awesome_mosaic),
            label: 'Intelligence',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            activeIcon: Icon(Icons.science),
            label: 'Simulate',
          ),
        ],
      ),
    );
  }
}
