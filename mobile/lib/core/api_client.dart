import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../features/explore/graph_models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;

  ApiException(this.message, {this.statusCode, this.uri});

  @override
  String toString() => 'ApiException: $message (Status: ${statusCode ?? "N/A"}, URL: $uri)';
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException(String message, {Uri? uri})
      : super(message, statusCode: 408, uri: uri);
}

class ApiConnectionException extends ApiException {
  ApiConnectionException(String message, {Uri? uri})
      : super(message, statusCode: null, uri: uri);
}

class ApiParseException extends ApiException {
  ApiParseException(String message, {Uri? uri})
      : super(message, statusCode: null, uri: uri);
}

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient();

  String baseUrl;
  final http.Client _httpClient;
  final Duration timeoutDuration;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.timeoutDuration = const Duration(seconds: 10),
  })  : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _httpClient = httpClient ?? http.Client();

  static String _getDefaultBaseUrl() {
    // Standard default: localhost works across Web, Desktop, and Android with adb reverse
    return 'http://localhost:8000/api/v1';
  }

  void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }

  /// Generic GET request with timeout and exception translation.
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final rawUri = Uri.parse('$baseUrl$cleanEndpoint');

    // Build query parameters safely
    final Map<String, dynamic> cleanParams = {};
    if (queryParams != null) {
      queryParams.forEach((key, value) {
        if (value != null) {
          if (value is Iterable) {
            cleanParams[key] = value.map((e) => e.toString()).toList();
          } else {
            cleanParams[key] = value.toString();
          }
        }
      });
    }

    final uri = cleanParams.isNotEmpty
        ? rawUri.replace(queryParameters: cleanParams)
        : rawUri;

    try {
      final response = await _httpClient
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeoutDuration);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw ApiParseException(
            'Failed to parse server response as valid JSON: $e',
            uri: uri,
          );
        }
      } else {
        throw ApiException(
          'Intelligence Engine returned HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
          uri: uri,
        );
      }
    } on TimeoutException {
      throw ApiTimeoutException(
        'Connection timed out after ${timeoutDuration.inSeconds} seconds. Please check if the backend is running.',
        uri: uri,
      );
    } on SocketException catch (e) {
      throw ApiConnectionException(
        'Failed to connect to backend server at $baseUrl. Ensure FastAPI server is running on port 8000. ($e)',
        uri: uri,
      );
    } on http.ClientException catch (e) {
      throw ApiConnectionException(
        'HTTP client connection failure: $e',
        uri: uri,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e', uri: uri);
    }
  }

  /// Fetches the dependency graph payload from the backend GET /graph endpoint.
  Future<DependencyGraphData> fetchDependencyGraph({
    List<String>? relationshipTypes,
    String? minRiskLevel,
    int? maxDepth,
    String? centerNodeId,
  }) async {
    final Map<String, dynamic> params = {};
    if (relationshipTypes != null && relationshipTypes.isNotEmpty) {
      params['relationship_types'] = relationshipTypes;
    }
    if (minRiskLevel != null && minRiskLevel.isNotEmpty && minRiskLevel != 'all') {
      params['min_risk_level'] = minRiskLevel;
    }
    if (maxDepth != null) {
      params['max_depth'] = maxDepth;
    }
    if (centerNodeId != null && centerNodeId.isNotEmpty) {
      params['center_node_id'] = centerNodeId;
    }

    final data = await get('/graph', queryParams: params);
    if (data is Map<String, dynamic>) {
      return DependencyGraphData.fromJson(data);
    } else {
      throw ApiParseException('Expected JSON object for dependency graph payload');
    }
  }

  /// Fetches propagation paths from hazard to target.
  Future<List<ClimaPropagationPath>> fetchPropagationPaths({
    String hazardId = 'hz_taiwan_drought',
    String targetId = 'comp_nvidia',
  }) async {
    final data = await get(
      '/graph/propagation',
      queryParams: {'hazard_id': hazardId, 'target_id': targetId},
    );
    if (data is List) {
      return data
          .map((item) => ClimaPropagationPath.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
