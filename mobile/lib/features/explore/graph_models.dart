import 'package:flutter/material.dart';

enum GraphNodeType {
  company,
  supplier,
  customer,
  facility,
  commodity,
  transportRoute,
  geographicRegion,
  climateHazard;

  static GraphNodeType fromString(String? val) {
    if (val == null) return GraphNodeType.company;
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'company':
        return GraphNodeType.company;
      case 'supplier':
        return GraphNodeType.supplier;
      case 'customer':
        return GraphNodeType.customer;
      case 'facility':
        return GraphNodeType.facility;
      case 'commodity':
        return GraphNodeType.commodity;
      case 'transport_route':
      case 'transportroute':
        return GraphNodeType.transportRoute;
      case 'geographic_region':
      case 'geographicregion':
        return GraphNodeType.geographicRegion;
      case 'climate_hazard':
      case 'climatehazard':
        return GraphNodeType.climateHazard;
      default:
        return GraphNodeType.company;
    }
  }

  String get apiValue {
    switch (this) {
      case GraphNodeType.company:
        return 'company';
      case GraphNodeType.supplier:
        return 'supplier';
      case GraphNodeType.customer:
        return 'customer';
      case GraphNodeType.facility:
        return 'facility';
      case GraphNodeType.commodity:
        return 'commodity';
      case GraphNodeType.transportRoute:
        return 'transport_route';
      case GraphNodeType.geographicRegion:
        return 'geographic_region';
      case GraphNodeType.climateHazard:
        return 'climate_hazard';
    }
  }
}

enum GraphRiskLevel {
  low,
  medium,
  high,
  critical;

  static GraphRiskLevel fromString(String? val) {
    if (val == null) return GraphRiskLevel.low;
    switch (val.toLowerCase()) {
      case 'critical':
        return GraphRiskLevel.critical;
      case 'high':
        return GraphRiskLevel.high;
      case 'medium':
        return GraphRiskLevel.medium;
      case 'low':
      default:
        return GraphRiskLevel.low;
    }
  }
}

class ClimaNode {
  final String id;
  final String label;
  final GraphNodeType type;
  final GraphRiskLevel riskLevel;
  final double riskScore;
  final String? sector;
  final String? location;
  final Offset position;
  final Map<String, dynamic> properties;

  const ClimaNode({
    required this.id,
    required this.label,
    required this.type,
    required this.riskLevel,
    required this.riskScore,
    this.sector,
    this.location,
    required this.position,
    this.properties = const {},
  });

  factory ClimaNode.fromJson(Map<String, dynamic> json) {
    final double posX = (json['x'] is num) ? (json['x'] as num).toDouble() : 100.0;
    final double posY = (json['y'] is num) ? (json['y'] as num).toDouble() : 100.0;

    return ClimaNode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['id']?.toString() ?? '',
      type: GraphNodeType.fromString(json['type']?.toString()),
      riskLevel: GraphRiskLevel.fromString(json['risk_level']?.toString()),
      riskScore: (json['risk_score'] is num)
          ? (json['risk_score'] as num).toDouble()
          : 0.0,
      sector: json['sector']?.toString(),
      location: json['location']?.toString(),
      position: Offset(posX, posY),
      properties: (json['properties'] is Map)
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : {},
    );
  }

  String get typeLabel {
    switch (type) {
      case GraphNodeType.company:
        return 'Company';
      case GraphNodeType.supplier:
        return 'Supplier';
      case GraphNodeType.customer:
        return 'Customer';
      case GraphNodeType.facility:
        return 'Facility';
      case GraphNodeType.commodity:
        return 'Commodity';
      case GraphNodeType.transportRoute:
        return 'Transport Route';
      case GraphNodeType.geographicRegion:
        return 'Region';
      case GraphNodeType.climateHazard:
        return 'Climate Hazard';
    }
  }

  IconData get icon {
    switch (type) {
      case GraphNodeType.company:
        return Icons.business;
      case GraphNodeType.supplier:
        return Icons.inventory_2_outlined;
      case GraphNodeType.customer:
        return Icons.account_balance;
      case GraphNodeType.facility:
        return Icons.factory_outlined;
      case GraphNodeType.commodity:
        return Icons.water_drop_outlined;
      case GraphNodeType.transportRoute:
        return Icons.alt_route;
      case GraphNodeType.geographicRegion:
        return Icons.public;
      case GraphNodeType.climateHazard:
        return Icons.warning_amber_rounded;
    }
  }
}

class ClimaEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String label;
  final String relationshipType;
  final double weight;
  final Map<String, dynamic> properties;

  const ClimaEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.label,
    required this.relationshipType,
    this.weight = 1.0,
    this.properties = const {},
  });

  factory ClimaEdge.fromJson(Map<String, dynamic> json) {
    return ClimaEdge(
      id: json['id']?.toString() ?? '',
      sourceId: json['source']?.toString() ?? json['sourceId']?.toString() ?? '',
      targetId: json['target']?.toString() ?? json['targetId']?.toString() ?? '',
      label: json['label']?.toString() ?? json['relationship']?.toString() ?? '',
      relationshipType: json['relationship']?.toString() ?? 'depends_on',
      weight: (json['weight'] is num) ? (json['weight'] as num).toDouble() : 1.0,
      properties: (json['properties'] is Map)
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : {},
    );
  }
}

class ClimaPropagationPath {
  final List<String> pathNodes;
  final List<String> pathEdges;
  final String hazardId;
  final String targetId;
  final double cumulativeRisk;

  const ClimaPropagationPath({
    required this.pathNodes,
    required this.pathEdges,
    required this.hazardId,
    required this.targetId,
    required this.cumulativeRisk,
  });

  factory ClimaPropagationPath.fromJson(Map<String, dynamic> json) {
    return ClimaPropagationPath(
      pathNodes: (json['path_nodes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      pathEdges: (json['path_edges'] as List?)?.map((e) => e.toString()).toList() ?? [],
      hazardId: json['hazard_id']?.toString() ?? '',
      targetId: json['target_id']?.toString() ?? '',
      cumulativeRisk: (json['cumulative_risk'] is num)
          ? (json['cumulative_risk'] as num).toDouble()
          : 0.0,
    );
  }
}

class DependencyGraphData {
  final List<ClimaNode> nodes;
  final List<ClimaEdge> edges;
  final List<ClimaPropagationPath> propagationPaths;
  final Map<String, dynamic> metadata;

  const DependencyGraphData({
    required this.nodes,
    required this.edges,
    this.propagationPaths = const [],
    this.metadata = const {},
  });

  factory DependencyGraphData.fromJson(Map<String, dynamic> json) {
    final nodesList = (json['nodes'] as List?)
            ?.map((e) => ClimaNode.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final edgesList = (json['edges'] as List?)
            ?.map((e) => ClimaEdge.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final propList = (json['propagation_paths'] as List?)
            ?.map((e) => ClimaPropagationPath.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DependencyGraphData(
      nodes: nodesList,
      edges: edgesList,
      propagationPaths: propList,
      metadata: (json['metadata'] is Map)
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}
