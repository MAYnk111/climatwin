import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climatwin_mobile/features/explore/graph_models.dart';
import 'package:climatwin_mobile/features/explore/graph_geometry.dart';

void main() {
  group('GraphViewportGeometry Tests', () {
    test('Calculates bounding box correctly for empty nodes', () {
      final bounds = GraphViewportGeometry.computeGraphBounds([], margin: 50.0);
      expect(bounds.left, 0.0);
      expect(bounds.top, 0.0);
      expect(bounds.width, 100.0);
      expect(bounds.height, 100.0);
    });

    test('Calculates bounding box including node cards and margins', () {
      final nodes = [
        ClimaNode(
          id: 'node1',
          label: 'Node 1',
          type: GraphNodeType.company,
          riskLevel: GraphRiskLevel.high,
          riskScore: 75.0,
          position: const Offset(100.0, 200.0),
        ),
        ClimaNode(
          id: 'node2',
          label: 'Node 2',
          type: GraphNodeType.supplier,
          riskLevel: GraphRiskLevel.medium,
          riskScore: 50.0,
          position: const Offset(500.0, 400.0),
        ),
      ];

      // Node 1: left = 100 - 60 = 40, right = 100 + 60 = 160, top = 200 - 27 = 173, bottom = 200 + 27 = 227
      // Node 2: left = 500 - 60 = 440, right = 500 + 60 = 560, top = 400 - 27 = 373, bottom = 400 + 27 = 427
      // Overall bounds before margin: minX=40, maxX=560, minY=173, maxY=427
      // With margin = 60: minX=-20, maxX=620, minY=113, maxY=487
      // width = 620 - (-20) = 640, height = 487 - 113 = 374

      final bounds = GraphViewportGeometry.computeGraphBounds(nodes, margin: 60.0);
      expect(bounds.left, -20.0);
      expect(bounds.top, 113.0);
      expect(bounds.width, 640.0);
      expect(bounds.height, 374.0);
    });

    test('Handles negative coordinates correctly', () {
      final nodes = [
        ClimaNode(
          id: 'node_neg',
          label: 'Negative Node',
          type: GraphNodeType.climateHazard,
          riskLevel: GraphRiskLevel.critical,
          riskScore: 90.0,
          position: const Offset(-200.0, -150.0),
        ),
        ClimaNode(
          id: 'node_pos',
          label: 'Positive Node',
          type: GraphNodeType.company,
          riskLevel: GraphRiskLevel.low,
          riskScore: 20.0,
          position: const Offset(200.0, 150.0),
        ),
      ];

      final bounds = GraphViewportGeometry.computeGraphBounds(nodes, margin: 40.0);
      // node_neg left = -200 - 60 = -260. With margin 40 -> minX = -300
      // node_pos right = 200 + 60 = 260. With margin 40 -> maxX = 300
      expect(bounds.left, -300.0);
      expect(bounds.right, 300.0);
      expect(bounds.width, 600.0);
    });

    test('Computes uniform fit to viewport matrix centering properly', () {
      final graphBounds = const Rect.fromLTWH(0, 0, 1000, 500);
      const viewportSize = Size(400, 800); // Phone portrait

      final matrix = GraphViewportGeometry.computeFitToViewportMatrix(
        graphBounds: graphBounds,
        viewportSize: viewportSize,
        minScale: 0.20,
        extraPadding: 20.0,
      );

      final scale = matrix.getMaxScaleOnAxis();
      // Available width = 400 - 40 = 360 -> scaleX = 360 / 1000 = 0.36
      // Available height = 800 - 40 = 760 -> scaleY = 760 / 500 = 1.52
      // Uniform scale = min(0.36, 1.52) = 0.36
      expect(scale, closeTo(0.36, 0.001));

      // Bounds center: X = 500, Y = 250
      // Viewport center: X = 200, Y = 400
      // tx = 200 - (500 * 0.36) = 200 - 180 = 20
      // ty = 400 - (250 * 0.36) = 400 - 90 = 310
      final tx = matrix.getTranslation().x;
      final ty = matrix.getTranslation().y;
      expect(tx, closeTo(20.0, 0.01));
      expect(ty, closeTo(310.0, 0.01));
    });

    test('Handles zero or invalid viewport gracefully', () {
      final graphBounds = const Rect.fromLTWH(0, 0, 500, 500);
      final matrixZero = GraphViewportGeometry.computeFitToViewportMatrix(
        graphBounds: graphBounds,
        viewportSize: Size.zero,
      );
      expect(matrixZero, equals(Matrix4.identity()));

      final centerZero = GraphViewportGeometry.computeCenterOnNodeMatrix(
        nodePosition: const Offset(100, 100),
        viewportSize: Size.zero,
      );
      expect(centerZero, equals(Matrix4.identity()));
    });

    test('Computes center on node matrix accurately for mobile viewport', () {
      const nodePos = Offset(300.0, 450.0);
      const viewportSize = Size(390.0, 844.0); // iPhone 13 / typical mobile
      const scale = 0.85;

      final matrix = GraphViewportGeometry.computeCenterOnNodeMatrix(
        nodePosition: nodePos,
        viewportSize: viewportSize,
        targetScale: scale,
      );

      // tx = 390/2 - 300*0.85 = 195 - 255 = -60
      // ty = 844/2 - 450*0.85 = 422 - 382.5 = 39.5
      expect(matrix.getTranslation().x, closeTo(-60.0, 0.01));
      expect(matrix.getTranslation().y, closeTo(39.5, 0.01));
      expect(matrix.getMaxScaleOnAxis(), closeTo(scale, 0.001));
    });

    test('Viewport adaptation across landscape vs portrait orientation', () {
      final graphBounds = const Rect.fromLTWH(100, 100, 800, 600);
      const portrait = Size(400, 800);
      const landscape = Size(800, 400);

      final matrixPortrait = GraphViewportGeometry.computeFitToViewportMatrix(
        graphBounds: graphBounds,
        viewportSize: portrait,
      );
      final matrixLandscape = GraphViewportGeometry.computeFitToViewportMatrix(
        graphBounds: graphBounds,
        viewportSize: landscape,
      );

      // Both should produce valid, positive finite scales and translations
      expect(matrixPortrait.getMaxScaleOnAxis() > 0, isTrue);
      expect(matrixLandscape.getMaxScaleOnAxis() > 0, isTrue);
      expect(matrixPortrait.getTranslation().x.isFinite, isTrue);
      expect(matrixLandscape.getTranslation().y.isFinite, isTrue);
    });
  });
}
