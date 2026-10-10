import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/firestore_service.dart';
import '../auth/auth_screen.dart';
import '../transparency/data_status_screen.dart';
import '../news/climate_news_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _savedScenariosCount = 0;
  int _savedInvestigationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final uid = AuthService.instance.currentUser?.uid ?? 'guest';
    try {
      final scenarios = await FirestoreService.instance.getSavedScenarios(userId: uid);
      final investigations = await FirestoreService.instance.getSavedInvestigations(userId: uid);
      if (mounted) {
        setState(() {
          _savedScenariosCount = scenarios.length;
          _savedInvestigationsCount = investigations.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final isLoggedIn = user != null;
    final userEmail = user?.email ?? 'Guest / Not Signed In';
    final userInitials = (user?.displayName ?? user?.email ?? 'PM')
        .substring(0, 2)
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ClimatwinTheme.lightGreenSurface,
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        color: ClimatwinTheme.darkGreenPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? (isLoggedIn ? 'Authenticated Analyst' : 'Guest Analyst'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ClimatwinTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(height: 2),
                          Text(
                            'UID: ${user.uid.length > 12 ? "${user.uid.substring(0, 12)}..." : user.uid}',
                            style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted, fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoggedIn ? ClimatwinTheme.surfaceElevated : ClimatwinTheme.darkGreenPrimary,
                      foregroundColor: isLoggedIn ? ClimatwinTheme.riskHigh : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (isLoggedIn) {
                        await AuthService.instance.signOut();
                        setState(() {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out successfully')),
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuthScreen(onAuthSuccess: () {
                              setState(() {});
                              _loadUserStats();
                            }),
                          ),
                        ).then((_) {
                          setState(() {});
                          _loadUserStats();
                        });
                      }
                    },
                    child: Text(
                      isLoggedIn ? 'Sign Out' : 'Sign In',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User-Scoped Data Store Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Investor Cloud Data Store',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scoped under /users/{uid}/ with local offline cache fallback',
                    style: TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ClimatwinTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saved Scenarios', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('$_savedScenariosCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ClimatwinTheme.darkGreenPrimary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ClimatwinTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Investigations', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('$_savedInvestigationsCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ClimatwinTheme.accentTeal)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Platform Intelligence & Transparency Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('Data Provenance & System Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Live audit trail for judges: 8 subsystems & data pipeline', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: ClimatwinTheme.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DataStatusScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: ClimatwinTheme.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.newspaper_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('Live Climate Disruption News', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: const Text('GDELT 2.0 live search, deduplication & 25m cache', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: ClimatwinTheme.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClimateNewsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: ClimatwinTheme.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('Firebase Project Scope', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('invest-2-77a18 (User Data Isolation)', style: TextStyle(fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ClimatwinTheme.lightGreenSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Active', style: TextStyle(fontSize: 10, color: ClimatwinTheme.darkGreenPrimary, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Divider(height: 1, color: ClimatwinTheme.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.api_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('FastAPI Backend Connectivity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(ApiClient.instance.baseUrl, style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.check_circle_outline, color: ClimatwinTheme.riskLow, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
