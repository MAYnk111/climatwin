import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'graph_models.dart';

/// Geometry and viewport utility for dependency graph layout, bounds calculation,
/// and matrix transformation fitting.
class GraphViewportGeometry {
  static const double cardWidth = 120.0;
  static const double cardHeight = 54.0;
  static const double cardHalfWidth = 60.0;
  static const double cardHalfHeight = 27.0;

  /// Calculates complete bounding box of the graph including:
  /// - Full rendered dimensions of all node cards
  /// - Edge routes and arrowhead extents
  /// - Labels and connector ports
  /// - Margin padding
  static Rect computeGraphBounds(
    List<ClimaNode> nodes, {
    List<ClimaEdge>? edges,
    double margin = 60.0,
  }) {
    if (nodes.isEmpty) {
      return Rect.fromLTWH(0, 0, margin * 2, margin * 2);
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final node in nodes) {
      final left = node.position.dx - cardHalfWidth;
      final top = node.position.dy - cardHalfHeight;
      final right = node.position.dx + cardHalfWidth;
      final bottom = node.position.dy + cardHalfHeight;

      if (left < minX) minX = left;
      if (top < minY) minY = top;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    // Include edge extents if edges exist
    if (edges != null && edges.isNotEmpty) {
      final nodeMap = {for (var n in nodes) n.id: n.position};
      for (final edge in edges) {
        final p1 = nodeMap[edge.sourceId];
        final p2 = nodeMap[edge.targetId];
        if (p1 != null && p2 != null) {
          // Port positions
          final startPort = Offset(p1.dx + cardHalfWidth, p1.dy);
          final endPort = Offset(p2.dx - cardHalfWidth, p2.dy);
          if (startPort.dx < minX) minX = startPort.dx;
          if (startPort.dx > maxX) maxX = startPort.dx;
          if (endPort.dx < minX) minX = endPort.dx;
          if (endPort.dx > maxX) maxX = endPort.dx;
          if (p1.dy < minY) minY = p1.dy;
          if (p1.dy > maxY) maxY = p1.dy;
          if (p2.dy < minY) minY = p2.dy;
          if (p2.dy > maxY) maxY = p2.dy;
        }
      }
    }

    // Add padding margins
    minX -= margin;
    minY -= margin;
    maxX += margin;
    maxY += margin;

    final width = math.max(10.0, maxX - minX);
    final height = math.max(10.0, maxY - minY);

    return Rect.fromLTWH(minX, minY, width, height);
  }

  /// Computes a uniform scale and translation matrix that fits the entire graph bounds
  /// within available viewport dimensions, centering horizontally and vertically.
  static Matrix4 computeFitToViewportMatrix({
    required Rect graphBounds,
    required Size viewportSize,
    double minScale = 0.50,
    double maxScale = 1.20,
    double extraPadding = 16.0,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return Matrix4.identity();
    }

    final double availableWidth = math.max(10.0, viewportSize.width - extraPadding * 2);
    final double availableHeight = math.max(10.0, viewportSize.height - extraPadding * 2);

    final double scaleX = availableWidth / graphBounds.width;
    final double scaleY = availableHeight / graphBounds.height;

    // Preserve legibility: allow a balanced overview scale that lets users read cards clearly
    // while panning across the supply chain tiers.
    final double scale = (math.min(scaleX, scaleY)).clamp(minScale, maxScale);

    // Center coordinates
    final double boundsCenterX = graphBounds.left + graphBounds.width / 2.0;
    final double boundsCenterY = graphBounds.top + graphBounds.height / 2.0;

    final double viewportCenterX = viewportSize.width / 2.0;
    final double viewportCenterY = viewportSize.height / 2.0;

    final double tx = viewportCenterX - (boundsCenterX * scale);
    final double ty = viewportCenterY - (boundsCenterY * scale);

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  /// Computes centering matrix for a single node
  static Matrix4 computeCenterOnNodeMatrix({
    required Offset nodePosition,
    required Size viewportSize,
    double targetScale = 0.85,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return Matrix4.identity();
    }
    final double tx = (viewportSize.width / 2.0) - (nodePosition.dx * targetScale);
    final double ty = (viewportSize.height / 2.0) - (nodePosition.dy * targetScale);

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(targetScale);
  }
}
