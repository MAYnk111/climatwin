import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class ClimateNewsScreen extends StatefulWidget {
  const ClimateNewsScreen({super.key});

  @override
  State<ClimateNewsScreen> createState() => _ClimateNewsScreenState();
}

class _ClimateNewsScreenState extends State<ClimateNewsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _articles = [];
  String _sourceAttribution = 'GDELT Project 2.0 Global News Database';
  String _selectedTopic = 'Drought';
  String _currentQuery = 'drought semiconductor taiwan';

  final List<Map<String, String>> _topicPresets = [
    {
      'label': 'Taiwan Drought',
      'topic': 'Drought',
      'query': 'drought semiconductor taiwan',
    },
    {
      'label': 'Rhine River Shipping',
      'topic': 'Low River Flow',
      'query': 'rhine river low water barge freight',
    },
    {
      'label': 'Kaohsiung Port / Typhoon',
      'topic': 'Typhoon',
      'query': 'typhoon kaohsiung port shipping disruption',
    },
    {
      'label': 'Semiconductor Supply Chain',
      'topic': 'Supply Disruption',
      'query': 'semiconductor water shortage foundry fab',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient.instance.fetchGdeltNews(
        query: _currentQuery,
        topic: _selectedTopic,
      );

      if (mounted) {
        setState(() {
          _articles = res['articles'] as List<dynamic>? ?? [];
          _sourceAttribution = res['source'] as String? ?? 'GDELT Project 2.0';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _selectTopicPreset(Map<String, String> preset) {
    setState(() {
      _selectedTopic = preset['topic']!;
      _currentQuery = preset['query']!;
    });
    _fetchNews();
  }

  void _copyArticleUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ClimatwinTheme.surfaceElevated,
        content: Text('Source URL copied to clipboard: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Climate Disruption News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Feed',
            onPressed: _isLoading ? null : _fetchNews,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNews,
        color: ClimatwinTheme.darkGreenPrimary,
        child: Column(
          children: [
            // Attribution & Provenance Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: ClimatwinTheme.surfaceElevated,
              child: Row(
                children: [
                  const Icon(Icons.public, size: 18, color: ClimatwinTheme.darkGreenPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sourceAttribution,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                        ),
                        const Text(
                          'GDELT Doc 2.0 live search • 25m cache TTL • SHA-256 deduplication',
                          style: TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: ClimatwinTheme.lightGreenSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_articles.length} ITEMS',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ClimatwinTheme.darkGreenPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Topic Presets Horizontal List
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: ClimatwinTheme.surfaceCard,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _topicPresets.length,
                itemBuilder: (ctx, idx) {
                  final preset = _topicPresets[idx];
                  final isSelected = _selectedTopic == preset['topic'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        preset['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : ClimatwinTheme.textSecondary,
                        ),
                      ),
                      selectedColor: ClimatwinTheme.darkGreenPrimary,
                      backgroundColor: ClimatwinTheme.surfaceElevated,
                      onSelected: (_) => _selectTopicPreset(preset),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ClimatwinTheme.darkGreenPrimary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off, size: 40, color: ClimatwinTheme.riskHigh),
                                const SizedBox(height: 12),
                                Text(
                                  'Unable to load live news: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: ClimatwinTheme.darkGreenPrimary),
                                  onPressed: _fetchNews,
                                  child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _articles.isEmpty
                          ? const Center(
                              child: Text(
                                'No articles found matching query.',
                                style: TextStyle(color: ClimatwinTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: _articles.length,
                              itemBuilder: (ctx, idx) {
                                final art = _articles[idx] as Map<String, dynamic>;
                                final title = art['title'] as String? ?? 'Disruption Bulletin';
                                final domain = art['source_domain'] as String? ?? 'gdeltproject.org';
                                final dateStr = art['seen_date'] as String? ?? '';
                                final topic = art['hazard_topic'] as String? ?? _selectedTopic;
                                final isLive = art['is_live_feed'] as bool? ?? false;
                                final url = art['url'] as String? ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: ClimatwinTheme.surfaceCard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: ClimatwinTheme.borderSubtle),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Live badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isLive
                                                    ? ClimatwinTheme.lightGreenSurface
                                                    : ClimatwinTheme.surfaceElevated,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isLive
                                                      ? ClimatwinTheme.darkGreenPrimary.withOpacity(0.4)
                                                      : ClimatwinTheme.borderSubtle,
                                                ),
                                              ),
                                              child: Text(
                                                isLive ? 'LIVE GDELT 2.0' : 'VERIFIED BULLETIN',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: isLive
                                                      ? ClimatwinTheme.darkGreenPrimary
                                                      : ClimatwinTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: ClimatwinTheme.surfaceElevated,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                topic,
                                                style: const TextStyle(fontSize: 9, color: ClimatwinTheme.textSecondary),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              domain,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClimatwinTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                            color: ClimatwinTheme.textPrimary,
                                          ),
                                        ),
                                        if (dateStr.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Seen: $dateStr',
                                            style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              icon: const Icon(Icons.link, size: 14, color: ClimatwinTheme.darkGreenPrimary),
                                              label: const Text(
                                                'Copy Source Link',
                                                style: TextStyle(fontSize: 11, color: ClimatwinTheme.darkGreenPrimary, fontWeight: FontWeight.w600),
                                              ),
                                              onPressed: url.isNotEmpty ? () => _copyArticleUrl(url) : null,
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
      ),
    );
  }
}
