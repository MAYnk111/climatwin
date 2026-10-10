import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../intelligence/intelligence_screen.dart';

class AlertsScreen extends StatefulWidget {
  final void Function(String hazardId, String title)? onInvestigateAlert;

  const AlertsScreen({
    super.key,
    this.onInvestigateAlert,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertItem {
  final String id;
  final String title;
  final String impact;
  final String source;
  final String time;
  final String severity;
  final Color severityColor;
  final String targetNodeId;
  bool isRead;

  _AlertItem({
    required this.id,
    required this.title,
    required this.impact,
    required this.source,
    required this.time,
    required this.severity,
    required this.severityColor,
    required this.targetNodeId,
    this.isRead = false,
  });
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'all';
  bool _isPermissionGranted = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final allowed = await NotificationService.instance.isPermissionAllowed();
    if (mounted) {
      setState(() {
        _isPermissionGranted = allowed;
        _isCheckingPermission = false;
      });
    }
  }

  final List<_AlertItem> _alerts = [
    _AlertItem(
      id: 'alt_01',
      title: 'Taiwan Baoshan Reservoir Stage 2 Water Rationing',
      impact: 'Affects TSMC Fab 12 (Hsinchu) • Downstream impact on NVDA & AAPL',
      source: 'Taiwan Water Resources Agency (WRA)',
      time: '2 hours ago',
      severity: 'Critical',
      severityColor: ClimatwinTheme.riskCritical,
      targetNodeId: 'comp_tsmc',
      isRead: false,
    ),
    _AlertItem(
      id: 'alt_02',
      title: 'Rhine River Water Levels at Kaub Gauge Drop Below 40cm',
      impact: 'Freight barge draft limited to 45% • Affects BMW logistics',
      source: 'German Federal Waterways & Shipping Admin',
      time: '5 hours ago',
      severity: 'High',
      severityColor: ClimatwinTheme.riskHigh,
      targetNodeId: 'comp_bmw',
      isRead: false,
    ),
    _AlertItem(
      id: 'alt_03',
      title: 'Typhoon Gaemi Disruption at Kaohsiung Container Terminal',
      impact: 'Port backlog 48-72h • Semiconductor packaging delayed',
      source: 'Taiwan Port Authority Bulletin',
      time: '18 hours ago',
      severity: 'High',
      severityColor: ClimatwinTheme.riskHigh,
      targetNodeId: 'comp_aapl',
      isRead: true,
    ),
    _AlertItem(
      id: 'alt_04',
      title: 'EU Carbon Border Adjustment (CBAM) Phase-3 Reporting Rule',
      impact: 'Scope 3 emissions reporting mandatory for steel and aluminum imports',
      source: 'European Commission Climate Action Directorate',
      time: '1 day ago',
      severity: 'Moderate',
      severityColor: ClimatwinTheme.riskMedium,
      targetNodeId: 'comp_bmw',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _alerts.where((a) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'unread') return !a.isRead;
      return a.severity.toLowerCase() == _selectedFilter;
    }).toList();

    final unreadCount = _alerts.where((a) => !a.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate & Supply Alerts'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var a in _alerts) {
                    a.isRead = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All alerts marked as read')),
                );
              },
              child: const Text('Mark all read', style: TextStyle(color: ClimatwinTheme.darkGreenPrimary, fontSize: 13)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Device Notification Channel Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isPermissionGranted ? ClimatwinTheme.lightGreenSurface : ClimatwinTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isPermissionGranted
                    ? ClimatwinTheme.darkGreenPrimary.withOpacity(0.3)
                    : ClimatwinTheme.riskMedium.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPermissionGranted ? Icons.notifications_active_outlined : Icons.notifications_paused_outlined,
                  color: _isPermissionGranted ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.riskMedium,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPermissionGranted ? 'System Notifications Enabled' : 'Notifications Awaiting Permission',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isPermissionGranted ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.riskMedium,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _isPermissionGranted
                            ? 'Channel: climatwin_alerts • Ready for background push'
                            : 'POST_NOTIFICATIONS not yet granted on device',
                        style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final res = await NotificationService.instance.triggerTestNotification();
                    if (!mounted) return;
                    setState(() {
                      _isPermissionGranted = res.isPermissionGranted;
                    });
                    if (res.isCreated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F3E30),
                          content: Text('✓ System notification #${res.notificationId} posted to Android shade!'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else if (!res.isPermissionGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF854D0E),
                          content: Text('Permission required: Please allow notifications in device settings.'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF991B1B),
                          content: Text('Failed to post notification: ${res.errorMessage ?? "System error"}'),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  child: const Text('Test Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ClimatwinTheme.surfaceCard,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${_alerts.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Unread ($unreadCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('critical', 'Critical'),
                  const SizedBox(width: 8),
                  _buildFilterChip('high', 'High'),
                  const SizedBox(width: 8),
                  _buildFilterChip('moderate', 'Moderate'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Alerts List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none, size: 48, color: ClimatwinTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No alerts in this category',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final alert = filtered[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: alert.isRead ? ClimatwinTheme.surfaceCard : ClimatwinTheme.surfaceElevated,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Severity Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: alert.severityColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      alert.severity.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: alert.severityColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    alert.time,
                                    style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                                  ),
                                  const Spacer(),
                                  if (!alert.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: ClimatwinTheme.darkGreenPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Title
                              Text(
                                alert.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ClimatwinTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Impact
                              Text(
                                alert.impact,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ClimatwinTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Source attribution
                              Row(
                                children: [
                                  const Icon(Icons.verified_outlined, size: 13, color: ClimatwinTheme.accentTeal),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Evidence: ${alert.source}',
                                      style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Direct action: Investigate
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      setState(() => alert.isRead = !alert.isRead);
                                    },
                                    child: Text(
                                      alert.isRead ? 'Mark as unread' : 'Mark as read',
                                      style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ClimatwinTheme.darkGreenPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    icon: const Icon(Icons.auto_awesome_mosaic, size: 14),
                                    label: const Text('Investigate Propagation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    onPressed: () {
                                      setState(() => alert.isRead = true);
                                      if (widget.onInvestigateAlert != null) {
                                        widget.onInvestigateAlert!(alert.targetNodeId, alert.title);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (ctx) => Scaffold(
                                              appBar: AppBar(title: Text(alert.title)),
                                              body: IntelligenceScreen(
                                                targetId: alert.targetNodeId,
                                                hazardTitle: alert.title,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSel = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: ClimatwinTheme.lightGreenSurface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
        color: isSel ? ClimatwinTheme.textPrimary : ClimatwinTheme.textSecondary,
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }
}
