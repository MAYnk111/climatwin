import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ClimatwinTheme.lightGreenSurface,
                    child: const Text('PM', style: TextStyle(color: ClimatwinTheme.darkGreenPrimary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portfolio Manager', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary)),
                      Text('pm@fundmanager.com', style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('Firebase Authentication & Security', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Client-side session active', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {},
                ),
                const Divider(height: 1, color: ClimatwinTheme.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('Firestore Portfolio Sync', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Synchronized with Cloud Firestore', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {},
                ),
                const Divider(height: 1, color: ClimatwinTheme.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.api_outlined, color: ClimatwinTheme.darkGreenPrimary),
                  title: const Text('Intelligence Engine Backend URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('http://localhost:8000/api/v1', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
