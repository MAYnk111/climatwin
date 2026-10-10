import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../features/explore/graph_models.dart';
import '../features/intelligence/intelligence_models.dart';
import '../features/simulate/simulate_models.dart';

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
    this.timeoutDuration = const Duration(seconds: 35),
  })  : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _httpClient = httpClient ?? http.Client();

  static String _getDefaultBaseUrl() {
    return 'https://climatwin-backend.onrender.com/api/v1';
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
        'Connection timed out after ${timeoutDuration.inSeconds} seconds. The backend may be waking up on Render.',
        uri: uri,
      );
    } on SocketException catch (e) {
      throw ApiConnectionException(
        'Failed to connect to backend server at $baseUrl. ($e)',
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

  /// Generic POST request with timeout and exception translation.
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$baseUrl$cleanEndpoint');

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: body != null ? jsonEncode(body) : null,
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
        'Connection timed out after ${timeoutDuration.inSeconds} seconds. The backend may be waking up on Render.',
        uri: uri,
      );
    } on SocketException catch (e) {
      throw ApiConnectionException(
        'Failed to connect to backend server at $baseUrl. ($e)',
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
    bool includeSectivia = false,
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
    if (includeSectivia) {
      params['include_sectivia'] = 'true';
    }

    final data = await get('/graph', queryParams: params);
    if (data is Map<String, dynamic>) {
      return DependencyGraphData.fromJson(data);
    } else {
      throw ApiParseException('Expected JSON object for dependency graph payload');
    }
  }

  /// Fetches CMIP6 climate model projections from World Bank CCKP adapter.
  Future<dynamic> fetchCountryProjections({
    String countryCode = 'TWN',
    String variable = 'tas',
  }) async {
    return await get('/climate/cckp', queryParams: {
      'country_code': countryCode,
      'variable': variable,
    });
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

  /// Runs the LangGraph AI risk investigation workflow.
  Future<InvestigationResult> runInvestigation({
    String hazardEventId = 'hz_taiwan_drought',
    String? targetId,
    String? hazardTitle,
    String? hazardDescription,
    Map<String, dynamic>? graphContext,
  }) async {
    final payload = {
      'hazard_event_id': hazardEventId,
      if (targetId != null) 'target_id': targetId,
      if (hazardTitle != null) 'hazard_title': hazardTitle,
      if (hazardDescription != null) 'hazard_description': hazardDescription,
      if (graphContext != null) 'graph_context': graphContext,
    };

    final data = await post('/intelligence/investigate', body: payload);
    if (data is Map<String, dynamic>) {
      return InvestigationResult.fromJson(data);
    } else {
      throw ApiParseException('Expected JSON object for investigation response');
    }
  }

  /// Runs the climate scenario stress test simulation.
  Future<SimulationResult> runSimulation({
    double severityMultiplier = 1.8,
    int durationMonths = 4,
    bool adaptationActive = true,
    bool alternativeSupplierActive = true,
    List<String>? targetHoldingTickers,
  }) async {
    final payload = {
      'severity_multiplier': severityMultiplier,
      'duration_months': durationMonths,
      'adaptation_mitigation_active': adaptationActive,
      'alternative_supplier_available': alternativeSupplierActive,
      if (targetHoldingTickers != null)
        'target_holding_tickers': targetHoldingTickers,
    };

    final data = await post('/simulations/run', body: payload);
    if (data is Map<String, dynamic>) {
      return SimulationResult.fromJson(data);
    } else {
      throw ApiParseException('Expected JSON object for simulation response');
    }
  }

  /// Fetches real-time environmental data via Open-Meteo adapter.
  Future<dynamic> fetchLiveWeather({
    String? regionCode,
    double? latitude,
    double? longitude,
  }) async {
    final queryParams = <String, String>{};
    if (regionCode != null) queryParams['region_code'] = regionCode;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();

    return await get('/adapters/climate/weather', queryParams: queryParams.isNotEmpty ? queryParams : null);
  }

  /// Fetches live USD/INR exchange rate from open exchange rate service.
  Future<Map<String, dynamic>> fetchMarketFxRate() async {
    final data = await get('/adapters/market/fx-rate');
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiParseException('Expected JSON object for market FX response');
  }

  /// Fetches verified climate news bulletins feed.
  Future<List<dynamic>> fetchClimateNewsFeed() async {
    final data = await get('/adapters/news/feed');
    if (data is List) {
      return data;
    }
    throw ApiParseException('Expected JSON array for news feed');
  }

  /// Fetches live GDELT 2.0 climate disruption news articles with 25-minute TTL caching.
  Future<Map<String, dynamic>> fetchGdeltNews({
    String query = 'drought semiconductor taiwan',
    String topic = 'Drought',
  }) async {
    final data = await get(
      '/climate/gdelt',
      queryParams: {
        'query': query,
        'topic': topic,
      },
    );
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiParseException('Expected JSON object for GDELT news response');
  }

  /// Calculates quantitative physical risk with attribution and calibration metadata.
  Future<PhysicalRiskResult> calculatePhysicalRisk({
    String hazardId = 'hz_taiwan_drought',
    String hazardTitle = 'Central Taiwan Extreme Drought',
    String targetNodeId = 'comp_nvidia',
    double portfolioAumUsd = 250000000.0,
    bool hasSecondarySupplier = false,
    bool hasOnsiteMitigation = false,
    bool synthesizeWithGemini = true,
    Map<String, double>? weights,
  }) async {
    final payload = {
      'hazard_id': hazardId,
      'hazard_title': hazardTitle,
      'target_node_id': targetNodeId,
      'portfolio_aum_usd': portfolioAumUsd,
      'has_secondary_supplier': hasSecondarySupplier,
      'has_onsite_mitigation': hasOnsiteMitigation,
      'synthesize_with_gemini': synthesizeWithGemini,
      if (weights != null) 'weights': weights,
    };
    final data = await post('/risk/calculate', body: payload);
    if (data is Map<String, dynamic>) {
      return PhysicalRiskResult.fromJson(data);
    } else {
      throw ApiParseException('Expected JSON object for risk calculation response');
    }
  }

  /// Fetches dataset calibration audit findings.
  Future<Map<String, dynamic>> fetchCalibrationAudit() async {
    final data = await get('/risk/calibration/audit');
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiParseException('Expected JSON object for calibration audit');
  }

  /// Fetches multi-profile sensitivity analysis across the 3-pillar simplex.
  Future<Map<String, dynamic>> fetchSensitivityAnalysis() async {
    final data = await get('/risk/calibration/sensitivity');
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiParseException('Expected JSON object for sensitivity report');
  }
}


