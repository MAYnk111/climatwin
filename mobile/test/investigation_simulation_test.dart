import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:climatwin_mobile/core/api_client.dart';
import 'package:climatwin_mobile/core/theme.dart';
import 'package:climatwin_mobile/features/intelligence/intelligence_models.dart';
import 'package:climatwin_mobile/features/intelligence/intelligence_screen.dart';
import 'package:climatwin_mobile/features/simulate/simulate_models.dart';
import 'package:climatwin_mobile/features/simulate/simulate_screen.dart';

const String sampleInvestigationJson = '''
{
  "investigation_id": "inv_001",
  "portfolio_id": "cust_global_tech_fund",
  "hazard_event_id": "hz_taiwan_drought",
  "hazard_title": "Central Taiwan Extreme Drought",
  "hazard_description": "Severe drought impacting Baoshan reservoir.",
  "evidence_items": [
    {
      "id": "ev_01",
      "source_name": "Taiwan Water Resources Agency",
      "source_url": "https://wip.wra.gov.tw/demo",
      "title": "Reservoir Capacity Dropped Below 18%",
      "snippet": "Baoshan No. 2 water reserves triggered Stage 2 restrictions.",
      "timestamp": "2026-10-08T12:00:00Z",
      "reliability_score": 0.95
    }
  ],
  "impacted_holdings": [
    {
      "ticker": "NVDA",
      "holding_name": "NVIDIA Corp",
      "weight": 0.09,
      "tier_exposure": 1,
      "direct_impact": false
    }
  ],
  "graph_propagation_paths": [
    ["hz_taiwan_drought", "fac_fab12", "sup_tsmc", "comp_nvidia"]
  ],
  "risk_summary": "Extreme drought in Hsinchu restricts ultrapure water.",
  "estimated_portfolio_impact_pct": -4.2,
  "confidence_score": 0.88,
  "uncertainty_range_pct": [-5.8, -3.1],
  "mitigation_recommendations": [
    {
      "action": "Secondary foundry qualification (Intel 18A)",
      "impact_reduction_pct": 1.8,
      "feasibility": "Medium"
    }
  ],
  "status": "completed",
  "is_modelled_data": true
}
''';

const String sampleSimulationJson = '''
{
  "scenario_id": "scen_q4_water_stress",
  "scenario_name": "Q4 Taiwan Severe Drought & Packaging Bottleneck",
  "baseline_total_aum": 65000000.0,
  "stressed_total_aum": 62156000.0,
  "net_portfolio_loss_usd": 2844000.0,
  "portfolio_drawdown_pct": 4.38,
  "stressed_holdings": [
    {
      "ticker": "AAPL",
      "name": "Apple Inc.",
      "baseline_value_usd": 30000000.0,
      "stressed_value_usd": 28812000.0,
      "loss_usd": 1188000.0,
      "drawdown_pct": 3.96,
      "mitigation_savings_usd": 2772000.0
    },
    {
      "ticker": "NVDA",
      "name": "NVIDIA Corp",
      "baseline_value_usd": 22500000.0,
      "stressed_value_usd": 21204000.0,
      "loss_usd": 1296000.0,
      "drawdown_pct": 5.76,
      "mitigation_savings_usd": 3024000.0
    }
  ],
  "branch_comparison": {
    "unmitigated_drawdown_pct": 14.58,
    "current_simulated_drawdown_pct": 4.38
  },
  "is_modelled_data": true
}
''';

void main() {
  group('Investigation API & Screen Tests', () {
    test('Correctly parses investigation JSON into typed model', () {
      final jsonMap = jsonDecode(sampleInvestigationJson) as Map<String, dynamic>;
      final result = InvestigationResult.fromJson(jsonMap);

      expect(result.investigationId, 'inv_001');
      expect(result.hazardEventId, 'hz_taiwan_drought');
      expect(result.estimatedPortfolioImpactPct, -4.2);
      expect(result.confidenceScore, 0.88);
      expect(result.uncertaintyRangePct, [-5.8, -3.1]);
      expect(result.evidenceItems.length, 1);
      expect(result.evidenceItems.first.sourceName, 'Taiwan Water Resources Agency');
      expect(result.impactedHoldings.length, 1);
      expect(result.impactedHoldings.first.ticker, 'NVDA');
      expect(result.graphPropagationPaths.length, 1);
      expect(result.mitigationRecommendations.first.impactReductionPct, 1.8);
    });

    testWidgets('IntelligenceScreen renders live findings, uncertainty, and evidence', (tester) async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/intelligence/investigate');
        return http.Response(sampleInvestigationJson, 200, headers: {
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
          body: IntelligenceScreen(apiClient: apiClient),
        ),
      ));

      // Settle async HTTP request
      await tester.pumpAndSettle();

      // Verify findings
      expect(find.text('Central Taiwan Extreme Drought'), findsOneWidget);
      expect(find.text('-4.2%'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('-5.8% to -3.1%'), findsOneWidget);

      // Verify evidence item rendered
      expect(find.text('Taiwan Water Resources Agency'), findsOneWidget);
      expect(find.text('95% Confidence'), findsOneWidget);

      // Verify mitigation action rendered
      expect(find.text('Secondary foundry qualification (Intel 18A)'), findsOneWidget);
    });
  });

  group('Simulation API & Screen Tests', () {
    test('Correctly parses simulation JSON into typed model', () {
      final jsonMap = jsonDecode(sampleSimulationJson) as Map<String, dynamic>;
      final result = SimulationResult.fromJson(jsonMap);

      expect(result.baselineTotalAum, 65000000.0);
      expect(result.stressedTotalAum, 62156000.0);
      expect(result.portfolioDrawdownPct, 4.38);
      expect(result.stressedHoldings.length, 2);
      expect(result.stressedHoldings.first.ticker, 'AAPL');
      expect(result.branchComparison['unmitigated_drawdown_pct'], 14.58);
    });

    testWidgets('SimulateScreen renders backend stress test results', (tester) async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/simulations/run');
        return http.Response(sampleSimulationJson, 200, headers: {
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
          body: SimulateScreen(apiClient: apiClient),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify baseline vs stressed numbers from backend
      expect(find.text('\$65.0M'), findsOneWidget);
      expect(find.text('\$62.2M'), findsOneWidget);
      expect(find.textContaining('4.38%'), findsWidgets);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('NVDA'), findsOneWidget);
    });
  });
}
