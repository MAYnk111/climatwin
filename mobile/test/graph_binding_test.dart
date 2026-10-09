import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:climatwin_mobile/core/api_client.dart';
import 'package:climatwin_mobile/core/theme.dart';
import 'package:climatwin_mobile/features/explore/graph_models.dart';
import 'package:climatwin_mobile/features/explore/graph_canvas.dart';

const String sampleBackendGraphJson = '''
{
  "nodes": [
    {
      "id": "hz_taiwan_drought",
      "label": "Central Taiwan Extreme Drought",
      "type": "climate_hazard",
      "risk_level": "critical",
      "risk_score": 92.0,
      "sector": null,
      "location": "Taichung / Hsinchu, Taiwan",
      "properties": {"hazard_type": "Drought", "is_demo": true, "confidence": 0.88},
      "x": 200.0,
      "y": 400.0
    },
    {
      "id": "sup_tsmc",
      "label": "TSMC (Contract Foundry)",
      "type": "supplier",
      "risk_level": "high",
      "risk_score": 84.0,
      "sector": "Semiconductors",
      "location": "Taiwan",
      "properties": {"tier": 1, "is_demo": true},
      "x": 600.0,
      "y": 400.0
    },
    {
      "id": "comp_nvidia",
      "label": "NVIDIA Corp (NVDA)",
      "type": "company",
      "risk_level": "high",
      "risk_score": 79.0,
      "sector": "Semiconductors & AI",
      "location": "Santa Clara, USA",
      "properties": {"portfolio_weight": 0.09, "is_demo": true},
      "x": 800.0,
      "y": 400.0
    }
  ],
  "edges": [
    {
      "id": "e_hz_to_sup",
      "source": "hz_taiwan_drought",
      "target": "sup_tsmc",
      "relationship": "exposed_to",
      "label": "disrupts wafer supply",
      "weight": 0.9,
      "properties": {}
    },
    {
      "id": "e_sup_to_comp",
      "source": "sup_tsmc",
      "target": "comp_nvidia",
      "relationship": "supplies_to",
      "label": "exclusive GPU foundry",
      "weight": 0.95,
      "properties": {}
    }
  ],
  "propagation_paths": [
    {
      "path_nodes": ["hz_taiwan_drought", "sup_tsmc", "comp_nvidia"],
      "path_edges": ["e_hz_to_sup", "e_sup_to_comp"],
      "hazard_id": "hz_taiwan_drought",
      "target_id": "comp_nvidia",
      "cumulative_risk": 78.2
    }
  ],
  "metadata": {
    "total_nodes": 3,
    "total_edges": 2
  }
}
''';

void main() {
  group('1. Graph JSON Parsing & Model Tests', () {
    test('Correctly parses backend graph payload', () {
      final jsonMap = jsonDecode(sampleBackendGraphJson) as Map<String, dynamic>;
      final graphData = DependencyGraphData.fromJson(jsonMap);

      expect(graphData.nodes.length, 3);
      expect(graphData.edges.length, 2);
      expect(graphData.propagationPaths.length, 1);

      // Verify Typed Nodes
      final hazardNode = graphData.nodes.firstWhere((n) => n.id == 'hz_taiwan_drought');
      expect(hazardNode.type, GraphNodeType.climateHazard);
      expect(hazardNode.riskLevel, GraphRiskLevel.critical);
      expect(hazardNode.riskScore, 92.0);
      expect(hazardNode.properties['hazard_type'], 'Drought');

      final supplierNode = graphData.nodes.firstWhere((n) => n.id == 'sup_tsmc');
      expect(supplierNode.type, GraphNodeType.supplier);
      expect(supplierNode.sector, 'Semiconductors');

      final companyNode = graphData.nodes.firstWhere((n) => n.id == 'comp_nvidia');
      expect(companyNode.type, GraphNodeType.company);

      // Verify Directional Edges
      final edge = graphData.edges.firstWhere((e) => e.id == 'e_hz_to_sup');
      expect(edge.sourceId, 'hz_taiwan_drought');
      expect(edge.targetId, 'sup_tsmc');
      expect(edge.relationshipType, 'exposed_to');
      expect(edge.label, 'disrupts wafer supply');

      // Verify Propagation Path
      final path = graphData.propagationPaths.first;
      expect(path.hazardId, 'hz_taiwan_drought');
      expect(path.targetId, 'comp_nvidia');
      expect(path.pathNodes, ['hz_taiwan_drought', 'sup_tsmc', 'comp_nvidia']);
      expect(path.cumulativeRisk, 78.2);
    });

    test('Node type fromString handles all variants and snake_case', () {
      expect(GraphNodeType.fromString('climate_hazard'), GraphNodeType.climateHazard);
      expect(GraphNodeType.fromString('transport_route'), GraphNodeType.transportRoute);
      expect(GraphNodeType.fromString('geographic_region'), GraphNodeType.geographicRegion);
      expect(GraphNodeType.fromString('facility'), GraphNodeType.facility);
      expect(GraphNodeType.fromString('commodity'), GraphNodeType.commodity);
      expect(GraphNodeType.fromString('supplier'), GraphNodeType.supplier);
      expect(GraphNodeType.fromString('company'), GraphNodeType.company);
      expect(GraphNodeType.fromString('customer'), GraphNodeType.customer);
    });

    test('Risk level fromString parses all levels correctly', () {
      expect(GraphRiskLevel.fromString('critical'), GraphRiskLevel.critical);
      expect(GraphRiskLevel.fromString('high'), GraphRiskLevel.high);
      expect(GraphRiskLevel.fromString('medium'), GraphRiskLevel.medium);
      expect(GraphRiskLevel.fromString('low'), GraphRiskLevel.low);
    });
  });

  group('2. Coordinate Stability & Ordering Tests', () {
    test('Coordinates are stable and maintain deterministic layout', () {
      final jsonMap = jsonDecode(sampleBackendGraphJson) as Map<String, dynamic>;
      final parse1 = DependencyGraphData.fromJson(jsonMap);
      final parse2 = DependencyGraphData.fromJson(jsonMap);

      for (int i = 0; i < parse1.nodes.length; i++) {
        expect(parse1.nodes[i].position.dx, parse2.nodes[i].position.dx);
        expect(parse1.nodes[i].position.dy, parse2.nodes[i].position.dy);
      }

      final hzNode = parse1.nodes.firstWhere((n) => n.id == 'hz_taiwan_drought');
      final supNode = parse1.nodes.firstWhere((n) => n.id == 'sup_tsmc');
      final compNode = parse1.nodes.firstWhere((n) => n.id == 'comp_nvidia');

      // Topological left-to-right tier structure
      expect(hzNode.position.dx < supNode.position.dx, isTrue);
      expect(supNode.position.dx < compNode.position.dx, isTrue);
    });
  });

  group('3. API Client & Error Handling Tests', () {
    test('fetchDependencyGraph successfully retrieves data on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/graph');
        return http.Response(sampleBackendGraphJson, 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'http://mock-server:8000/api/v1',
        httpClient: mockClient,
      );

      final result = await apiClient.fetchDependencyGraph();
      expect(result.nodes.length, 3);
      expect(result.edges.length, 2);
    });

    test('fetchDependencyGraph throws ApiException on HTTP 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://mock-server:8000/api/v1',
        httpClient: mockClient,
      );

      expect(
        () async => await apiClient.fetchDependencyGraph(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('fetchDependencyGraph throws ApiParseException on malformed JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{not-valid-json', 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'http://mock-server:8000/api/v1',
        httpClient: mockClient,
      );

      expect(
        () async => await apiClient.fetchDependencyGraph(),
        throwsA(isA<ApiParseException>()),
      );
    });
  });

  group('4. InteractiveDependencyGraph Widget Tests', () {
    testWidgets('Renders error view with retry button on backend failure', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Server connection error', 503);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        httpClient: mockClient,
      );

      await tester.pumpWidget(MaterialApp(
        theme: ClimatwinTheme.lightTheme,
        home: Scaffold(
          body: InteractiveDependencyGraph(apiClient: apiClient),
        ),
      ));

      // Initially shows loading
      expect(find.text('Fetching Dependency Graph...'), findsOneWidget);

      // Settle async HTTP request
      await tester.pumpAndSettle();

      // Displays clean error state
      expect(find.text('Backend Connection Failure'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
    });

    testWidgets('Renders nodes and triggers bottom sheet on node tap', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(sampleBackendGraphJson, 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        httpClient: mockClient,
      );

      await tester.pumpWidget(MaterialApp(
        theme: ClimatwinTheme.lightTheme,
        home: Scaffold(
          body: InteractiveDependencyGraph(apiClient: apiClient),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify nodes are rendered
      expect(find.text('TSMC (Contract Foundry)'), findsOneWidget);
      expect(find.text('NVIDIA Corp (NVDA)'), findsOneWidget);

      // Verify legend details
      expect(find.text('3 nodes • 2 edges (Backend Live)'), findsOneWidget);

      // Tap on TSMC node to trigger selection and bottom sheet
      await tester.tap(find.text('TSMC (Contract Foundry)'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with node details and relationships
      expect(find.text('Connected Relationships'), findsOneWidget);
      expect(find.text('Investigate Propagation Risk'), findsOneWidget);
    });
  });
}
