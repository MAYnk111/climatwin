import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/home/home_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/explore/graph_models.dart';
import '../features/intelligence/intelligence_screen.dart';
import '../features/simulate/simulate_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../features/market/market_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/transparency/data_status_screen.dart';
import '../features/news/climate_news_screen.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  ClimaNode? _activeInvestigationNode;
  String? _activeInvestigationHazardTitle;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.initialize(
      onNotificationTapped: (hazardId, title) {
        if (mounted) {
          _triggerInvestigationForAlert(hazardId, title);
        }
      },
      currentUserId: AuthService.instance.currentUser?.uid,
    );
  }

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

  void _triggerInvestigationForNode(ClimaNode node) {
    setState(() {
      _activeInvestigationNode = node;
      _activeInvestigationHazardTitle = 'Investigation for ${node.label}';
      _currentIndex = 2; // Jump straight to Intelligence tab
    });
  }

  void _triggerInvestigationForAlert(String targetNodeId, String title) {
    setState(() {
      _activeInvestigationNode = ClimaNode(
        id: targetNodeId,
        label: targetNodeId,
        type: GraphNodeType.company,
        riskScore: 80,
        riskLevel: GraphRiskLevel.high,
        position: Offset.zero,
      );
      _activeInvestigationHazardTitle = title;
      _currentIndex = 2; // Jump straight to Intelligence tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final screens = [
      HomeScreen(
        onExploreGraph: () => _navigateToTab(1),
        onInvestigate: () => _navigateToTab(2),
        onSimulate: () => _navigateToTab(3),
        onOpenWatchlist: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WatchlistScreen(
              onInspectInGraph: (_) => _navigateToTab(1),
              onSimulateShock: (_) => _navigateToTab(3),
            ),
          ),
        ),
        onOpenMarket: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketScreen()),
        ),
        onOpenAlerts: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertsScreen(
              onInvestigateAlert: (nodeId, title) {
                Navigator.pop(context);
                _triggerInvestigationForAlert(nodeId, title);
              },
            ),
          ),
        ),
      ),
      ExploreScreen(
        onInvestigateNode: _triggerInvestigationForNode,
      ),
      IntelligenceScreen(
        key: ValueKey(_activeInvestigationNode?.id ?? 'default_intelligence'),
        targetId: _activeInvestigationNode?.id,
        hazardTitle: _activeInvestigationHazardTitle,
      ),
      const SimulateScreen(),
    ];

    final appBarActions = [
      // Quick access to Watchlist
      IconButton(
        icon: const Icon(Icons.bookmark_outline, size: 22),
        tooltip: 'Portfolio Watchlist',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WatchlistScreen(
                onInspectInGraph: (_) => _navigateToTab(1),
                onSimulateShock: (_) => _navigateToTab(3),
              ),
            ),
          );
        },
      ),
      // Quick access to Markets & FX
      IconButton(
        icon: const Icon(Icons.candlestick_chart_outlined, size: 22),
        tooltip: 'Markets & Commodities (₹)',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketScreen()),
          );
        },
      ),
      // Quick access to Alerts with unread badge dot
      Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            tooltip: 'Climate Alerts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlertsScreen(
                    onInvestigateAlert: (nodeId, title) {
                      Navigator.pop(context);
                      _triggerInvestigationForAlert(nodeId, title);
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ClimatwinTheme.riskHigh,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      // Quick access to Live Climate News (GDELT)
      IconButton(
        icon: const Icon(Icons.newspaper_outlined, size: 21),
        tooltip: 'Live Climate News (GDELT 2.0)',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClimateNewsScreen()),
          );
        },
      ),
      // Quick access to Data Status & Audit Screen
      IconButton(
        icon: const Icon(Icons.verified_outlined, size: 21, color: ClimatwinTheme.accentTeal),
        tooltip: 'Data Provenance & System Status',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DataStatusScreen()),
          );
        },
      ),
      // Profile & Settings
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
    ];

    if (isDesktop) {
      // Responsive Desktop / Tablet Layout with Navigation Rail
      return Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          actions: appBarActions,
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _navigateToTab,
              labelType: NavigationRailLabelType.all,
              backgroundColor: ClimatwinTheme.surfaceCard,
              selectedIconTheme: const IconThemeData(color: ClimatwinTheme.darkGreenPrimary),
              selectedLabelTextStyle: const TextStyle(
                color: ClimatwinTheme.darkGreenPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: ClimatwinTheme.textSecondary,
                fontSize: 11,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text('Explore'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_mosaic_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_mosaic),
                  label: Text('Intelligence'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.science_outlined),
                  selectedIcon: Icon(Icons.science),
                  label: Text('Simulate'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: ClimatwinTheme.borderSubtle),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout with exact four bottom-navigation destinations
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: appBarActions,
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
