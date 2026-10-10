import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import 'graph_models.dart';
import 'graph_geometry.dart';

enum GraphViewState { loading, loaded, empty, error }

class InteractiveDependencyGraph extends StatefulWidget {
  final ApiClient? apiClient;
  final void Function(ClimaNode node)? onInvestigateNode;

  const InteractiveDependencyGraph({super.key, this.apiClient, this.onInvestigateNode});

  @override
  State<InteractiveDependencyGraph> createState() =>
      _InteractiveDependencyGraphState();
}

class _InteractiveDependencyGraphState extends State<InteractiveDependencyGraph> {
  final TransformationController _transformationController =
      TransformationController();

  late final ApiClient _apiClient;
  GraphViewState _state = GraphViewState.loading;
  String? _errorMessage;

  DependencyGraphData? _graphData;
  String? _selectedNodeId;
  String _selectedRiskFilter = 'all';
  String _selectedRelationshipFilter = 'all';
  int? _selectedMaxDepth;
  bool _highlightPropagation = true;

  Size _lastViewportSize = Size.zero;
  bool _hasUserInteracted = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient.instance;
    _fetchGraphData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void fitGraphToViewport({Size? viewportSize}) {
    if (_graphData == null || _graphData!.nodes.isEmpty) {
      _transformationController.value = Matrix4.identity()..scale(0.75);
      return;
    }
    final size = viewportSize ?? _lastViewportSize;
    if (size.width <= 0 || size.height <= 0) return;

    final bounds = GraphViewportGeometry.computeGraphBounds(
      _graphData!.nodes,
      edges: _graphData!.edges,
      margin: 40.0,
    );

    final matrix = GraphViewportGeometry.computeFitToViewportMatrix(
      graphBounds: bounds,
      viewportSize: size,
      minScale: 0.20,
      maxScale: 1.10,
      extraPadding: 16.0,
    );

    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _centerOnNode(ClimaNode node) {
    if (_lastViewportSize.width <= 0 || _lastViewportSize.height <= 0) return;
    final matrix = GraphViewportGeometry.computeCenterOnNodeMatrix(
      nodePosition: node.position,
      viewportSize: _lastViewportSize,
      targetScale: 0.90,
    );
    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _resetZoom() {
    fitGraphToViewport();
  }

  Future<void> _fetchGraphData() async {
    setState(() {
      _state = GraphViewState.loading;
      _errorMessage = null;
    });

    try {
      final List<String>? relTypes =
          _selectedRelationshipFilter == 'all' ? null : [_selectedRelationshipFilter];
      final String? minRisk =
          _selectedRiskFilter == 'all' ? null : (_selectedRiskFilter == 'high_plus' ? 'high' : 'critical');

      final data = await _apiClient.fetchDependencyGraph(
        relationshipTypes: relTypes,
        minRiskLevel: minRisk,
        maxDepth: _selectedMaxDepth,
        centerNodeId: _selectedNodeId,
      );

      if (mounted) {
        setState(() {
          _graphData = data;
          _state = data.nodes.isEmpty ? GraphViewState.empty : GraphViewState.loaded;
        });
        if (data.nodes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasUserInteracted) {
              fitGraphToViewport();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = GraphViewState.error;
          _errorMessage = e is ApiException
              ? e.message
              : 'Failed to connect to CLIMATWIN backend: $e';
        });
      }
    }
  }

  void _showNodeBottomSheet(ClimaNode node) {
    if (_graphData == null) return;

    final incomingEdges = _graphData!.edges
        .where((e) => e.targetId == node.id)
        .toList();
    final outgoingEdges = _graphData!.edges
        .where((e) => e.sourceId == node.id)
        .toList();

    final nodeMap = {for (var n in _graphData!.nodes) n.id: n};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NodeDetailBottomSheet(
        node: node,
        incomingEdges: incomingEdges,
        outgoingEdges: outgoingEdges,
        nodeMap: nodeMap,
        onInvestigate: (selected) {
          if (widget.onInvestigateNode != null) {
            widget.onInvestigateNode!(selected);
          } else {
            _showInSituInvestigationSheet(selected);
          }
        },
      ),
    );
  }

  void _showInSituInvestigationSheet(ClimaNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: ClimatwinTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              AppBar(
                title: Text('Investigation: ${node.label}'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              Expanded(
                child: FutureBuilder(
                  future: _apiClient.runInvestigation(
                    targetId: node.id,
                    hazardTitle: 'Propagation Exposure for ${node.label}',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: ClimatwinTheme.darkGreenPrimary));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Investigation error: ${snapshot.error}', style: const TextStyle(color: ClimatwinTheme.riskHigh)),
                        ),
                      );
                    }
                    final res = snapshot.data!;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Finding: ${res.riskSummary ?? "Exposure confirmed."}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Estimated Impact: ${res.estimatedPortfolioImpactPct}% (Confidence: ${(res.confidenceScore * 100).toInt()}%)', style: const TextStyle(color: ClimatwinTheme.riskHigh, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        const Text('Active Transmission Paths:', style: TextStyle(fontWeight: FontWeight.w700)),
                        ...res.graphPropagationPaths.map((p) => Text('• ${p.join(" → ")}', style: const TextStyle(fontSize: 11))),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Graph Control & Filter Strip
        _buildFilterToolbar(),

        // Dynamic View Area
        Expanded(
          child: switch (_state) {
            GraphViewState.loading => _buildLoadingView(),
            GraphViewState.error => _buildErrorView(),
            GraphViewState.empty => _buildEmptyView(),
            GraphViewState.loaded => _buildCanvasView(),
          },
        ),

        // Bottom Legend Strip
        if (_state == GraphViewState.loaded) _buildLegendToolbar(),
      ],
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: ClimatwinTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: ClimatwinTheme.borderSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Risk Filter Chips
            ChoiceChip(
              label: const Text('All Risks', style: TextStyle(fontSize: 11)),
              selected: _selectedRiskFilter == 'all',
              selectedColor: ClimatwinTheme.lightGreenSurface,
              onSelected: (val) {
                if (val && _selectedRiskFilter != 'all') {
                  setState(() => _selectedRiskFilter = 'all');
                  _fetchGraphData();
                }
              },
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('High & Critical', style: TextStyle(fontSize: 11)),
              selected: _selectedRiskFilter == 'high_plus',
              selectedColor: ClimatwinTheme.lightGreenSurface,
              onSelected: (val) {
                if (val && _selectedRiskFilter != 'high_plus') {
                  setState(() => _selectedRiskFilter = 'high_plus');
                  _fetchGraphData();
                }
              },
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Critical Only', style: TextStyle(fontSize: 11)),
              selected: _selectedRiskFilter == 'critical',
              selectedColor: ClimatwinTheme.lightGreenSurface,
              onSelected: (val) {
                if (val && _selectedRiskFilter != 'critical') {
                  setState(() => _selectedRiskFilter = 'critical');
                  _fetchGraphData();
                }
              },
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: ClimatwinTheme.borderSubtle),
            const SizedBox(width: 12),

            // Relationship Filter Dropdown
            DropdownButton<String>(
              value: _selectedRelationshipFilter,
              underline: const SizedBox.shrink(),
              style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textPrimary, fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Relationships')),
                DropdownMenuItem(value: 'supplies_to', child: Text('Supplies To')),
                DropdownMenuItem(value: 'depends_on', child: Text('Depends On')),
                DropdownMenuItem(value: 'exposed_to', child: Text('Exposed To')),
                DropdownMenuItem(value: 'located_in', child: Text('Located In')),
                DropdownMenuItem(value: 'owns', child: Text('Owns')),
              ],
              onChanged: (newVal) {
                if (newVal != null && newVal != _selectedRelationshipFilter) {
                  setState(() => _selectedRelationshipFilter = newVal);
                  _fetchGraphData();
                }
              },
            ),
            const SizedBox(width: 8),

            // Toggle Propagation Highlight
            IconButton(
              icon: Icon(
                _highlightPropagation ? Icons.alt_route : Icons.alt_route_outlined,
                color: _highlightPropagation
                    ? ClimatwinTheme.darkGreenPrimary
                    : ClimatwinTheme.textMuted,
                size: 20,
              ),
              tooltip: 'Toggle Hazard Propagation Highlight',
              onPressed: () {
                setState(() => _highlightPropagation = !_highlightPropagation);
              },
            ),

            // Fit Screen / Reset View
            IconButton(
              icon: const Icon(Icons.fit_screen, size: 20, color: ClimatwinTheme.textSecondary),
              tooltip: 'Fit to Screen',
              onPressed: _resetZoom,
            ),

            // Refresh / Reload from Server
            IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: ClimatwinTheme.textSecondary),
              tooltip: 'Refresh from Server',
              onPressed: _fetchGraphData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: ClimatwinTheme.darkGreenPrimary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          const Text(
            'Fetching Dependency Graph...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Querying intelligence engine at ${_apiClient.baseUrl}',
            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: ClimatwinTheme.riskHigh,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Backend Connection Failure',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ClimatwinTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Unable to connect to the intelligence engine.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ClimatwinTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Target Endpoint: ${_apiClient.baseUrl}/graph',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ClimatwinTheme.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Connection'),
                  onPressed: _fetchGraphData,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined, size: 40, color: ClimatwinTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Matching Graph Entities',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ClimatwinTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No nodes match the selected risk or relationship filters.',
              style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ClimatwinTheme.darkGreenPrimary,
                side: const BorderSide(color: ClimatwinTheme.darkGreenPrimary),
              ),
              onPressed: () {
                setState(() {
                  _selectedRiskFilter = 'all';
                  _selectedRelationshipFilter = 'all';
                  _selectedMaxDepth = null;
                  _selectedNodeId = null;
                });
                _fetchGraphData();
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasView() {
    final nodes = _graphData!.nodes;
    final edges = _graphData!.edges;

    // Extract propagation edge and node sets from backend response
    final Set<String> propagationNodeIds = {};
    final Set<String> propagationEdgeIds = {};
    for (final p in _graphData!.propagationPaths) {
      propagationNodeIds.addAll(p.pathNodes);
      propagationEdgeIds.addAll(p.pathEdges);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastViewportSize != viewportSize && viewportSize.width > 0 && viewportSize.height > 0) {
          final isFirstLayout = _lastViewportSize == Size.zero;
          _lastViewportSize = viewportSize;
          if (isFirstLayout || !_hasUserInteracted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) fitGraphToViewport(viewportSize: viewportSize);
            });
          }
        }

        final graphBounds = GraphViewportGeometry.computeGraphBounds(nodes, edges: edges, margin: 100.0);
        final double canvasWidth = math.max(1400.0, graphBounds.right + 200.0);
        final double canvasHeight = math.max(1100.0, graphBounds.bottom + 200.0);

        debugPrint('[GRAPH_DIAG] Canvas viewportSize: $viewportSize, nodes: ${nodes.length}, edges: ${edges.length}');
        debugPrint('[GRAPH_DIAG] graphBounds: $graphBounds, canvasSize: ($canvasWidth, $canvasHeight)');
        debugPrint('[GRAPH_DIAG] Current matrix: ${_transformationController.value}');

        return ClipRect(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            minScale: 0.20,
            maxScale: 3.0,
            boundaryMargin: EdgeInsets.all(math.max(viewportSize.width, viewportSize.height) * 1.5),
            onInteractionStart: (_) {
              _hasUserInteracted = true;
            },
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Directional Edges Layer
                  CustomPaint(
                    size: Size(canvasWidth, canvasHeight),
                    painter: _GraphEdgePainter(
                      edges: edges,
                      nodes: nodes,
                      propagationEdgeIds: _highlightPropagation ? propagationEdgeIds : {},
                      selectedNodeId: _selectedNodeId,
                    ),
                  ),
                  // Typed Nodes Layer
                  ...nodes.map((node) {
                    final isSelected = node.id == _selectedNodeId;
                    final isPropagation =
                        _highlightPropagation && propagationNodeIds.contains(node.id);

                    return Positioned(
                      left: node.position.dx - 60,
                      top: node.position.dy - 30,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNodeId = node.id;
                          });
                          _centerOnNode(node);
                          _showNodeBottomSheet(node);
                        },
                        child: _NodeWidget(
                          node: node,
                          isSelected: isSelected,
                          isPropagation: isPropagation,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendToolbar() {
    final int nodeCount = _graphData?.nodes.length ?? 0;
    final int edgeCount = _graphData?.edges.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ClimatwinTheme.surfaceCard,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: ClimatwinTheme.riskCritical,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text('Critical', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary)),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: ClimatwinTheme.riskHigh,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text('High', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary)),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: ClimatwinTheme.riskMedium,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text('Medium', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary)),
          const Spacer(),
          Text(
            '$nodeCount nodes • $edgeCount edges (Backend Live)',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ClimatwinTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final ClimaNode node;
  final bool isSelected;
  final bool isPropagation;

  const _NodeWidget({
    required this.node,
    required this.isSelected,
    required this.isPropagation,
  });

  Color _getRiskColor() {
    switch (node.riskLevel) {
      case GraphRiskLevel.critical:
        return ClimatwinTheme.riskCritical;
      case GraphRiskLevel.high:
        return ClimatwinTheme.riskHigh;
      case GraphRiskLevel.medium:
        return ClimatwinTheme.riskMedium;
      case GraphRiskLevel.low:
        return ClimatwinTheme.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ClimatwinTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? ClimatwinTheme.darkGreenPrimary
              : (isPropagation ? riskColor : ClimatwinTheme.borderSubtle),
          width: isSelected ? 2.5 : (isPropagation ? 1.8 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.14 : 0.04),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                node.icon,
                size: 14,
                color: isPropagation ? riskColor : ClimatwinTheme.darkGreenPrimary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  node.typeLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    color: ClimatwinTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${node.riskScore.toInt()}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            node.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GraphEdgePainter extends CustomPainter {
  final List<ClimaEdge> edges;
  final List<ClimaNode> nodes;
  final Set<String> propagationEdgeIds;
  final String? selectedNodeId;

  _GraphEdgePainter({
    required this.edges,
    required this.nodes,
    required this.propagationEdgeIds,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Offset> nodePositions = {
      for (var n in nodes) n.id: n.position,
    };

    final defaultPaint = Paint()
      ..color = ClimatwinTheme.borderSubtle
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final propagationPaint = Paint()
      ..color = ClimatwinTheme.riskHigh
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final edge in edges) {
      final start = nodePositions[edge.sourceId];
      final end = nodePositions[edge.targetId];

      if (start == null || end == null) continue;

      final isProp = propagationEdgeIds.contains(edge.id);
      final currentPaint = isProp ? propagationPaint : defaultPaint;

      // Draw curved bezier line from source to target
      final path = Path();
      path.moveTo(start.dx, start.dy);
      final controlX = (start.dx + end.dx) / 2;
      path.cubicTo(
        controlX,
        start.dy,
        controlX,
        end.dy,
        end.dx,
        end.dy,
      );
      canvas.drawPath(path, currentPaint);

      // Draw directional arrow near target
      final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final arrowPath = Path();
      const arrowSize = 6.0;
      arrowPath.moveTo(
        midPoint.dx + arrowSize * math.cos(angle),
        midPoint.dy + arrowSize * math.sin(angle),
      );
      arrowPath.lineTo(
        midPoint.dx + arrowSize * math.cos(angle + 2.5),
        midPoint.dy + arrowSize * math.sin(angle + 2.5),
      );
      arrowPath.lineTo(
        midPoint.dx + arrowSize * math.cos(angle - 2.5),
        midPoint.dy + arrowSize * math.sin(angle - 2.5),
      );
      arrowPath.close();

      final arrowFill = Paint()
        ..color = isProp ? ClimatwinTheme.riskHigh : ClimatwinTheme.textMuted
        ..style = PaintingStyle.fill;
      canvas.drawPath(arrowPath, arrowFill);

      // Edge relationship label
      textPainter.text = TextSpan(
        text: edge.label,
        style: TextStyle(
          color: isProp ? ClimatwinTheme.riskHigh : ClimatwinTheme.textMuted,
          fontSize: 8.5,
          fontWeight: isProp ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(midPoint.dx - textPainter.width / 2, midPoint.dy - 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphEdgePainter oldDelegate) => true;
}

class _NodeDetailBottomSheet extends StatelessWidget {
  final ClimaNode node;
  final List<ClimaEdge> incomingEdges;
  final List<ClimaEdge> outgoingEdges;
  final Map<String, ClimaNode> nodeMap;
  final void Function(ClimaNode node)? onInvestigate;

  const _NodeDetailBottomSheet({
    required this.node,
    required this.incomingEdges,
    required this.outgoingEdges,
    required this.nodeMap,
    this.onInvestigate,
  });


  @override
  Widget build(BuildContext context) {
    final riskColor = ClimatwinTheme.getRiskColor(node.riskLevel.name);

    return Container(
      decoration: const BoxDecoration(
        color: ClimatwinTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ClimatwinTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(node.icon, color: ClimatwinTheme.darkGreenPrimary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ClimatwinTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${node.typeLabel}${node.location != null ? " • ${node.location}" : ""}${node.sector != null ? " • ${node.sector}" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ClimatwinTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: riskColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${node.riskScore.toInt()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: riskColor,
                          ),
                        ),
                        Text(
                          node.riskLevel.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: ClimatwinTheme.borderSubtle),

              // Relationships Breakdown Section
              const Text(
                'Connected Relationships',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClimatwinTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              if (incomingEdges.isEmpty && outgoingEdges.isEmpty)
                const Text(
                  'No direct edges in current view.',
                  style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                ),

              ...incomingEdges.map((e) {
                final source = nodeMap[e.sourceId];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 12, color: ClimatwinTheme.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${source?.label ?? e.sourceId} ',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '— ${e.label}',
                                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              ...outgoingEdges.map((e) {
                final target = nodeMap[e.targetId];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, size: 12, color: ClimatwinTheme.darkGreenPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${e.label} → ',
                                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                              ),
                              TextSpan(
                                text: target?.label ?? e.targetId,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),


              const SizedBox(height: 14),

              // Node Properties & Evidence Section
              if (node.properties.isNotEmpty) ...[
                const Text(
                  'Node Evidence & Properties',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ClimatwinTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ...node.properties.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: ClimatwinTheme.textSecondary,
                            ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClimatwinTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Investigate Propagation Risk'),
                  onPressed: () {
                    Navigator.pop(context);
                    onInvestigate?.call(node);
                  },

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
