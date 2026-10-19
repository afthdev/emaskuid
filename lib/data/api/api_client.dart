import 'package:dio/dio.dart';

import 'package:emaskuid/core/config/app_config.dart';
import 'package:emaskuid/data/api/api_exception.dart';
import 'package:emaskuid/data/models/models.dart';

/// Thin wrapper over the Logam Mulia API.
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBase,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  final Dio _dio;

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final body = res.data;
      if (body is! Map) {
        throw ApiException('Format respons tidak dikenal dari $path');
      }
      final map = Map<String, dynamic>.from(body);
      if (map['success'] == false) {
        throw ApiException(map['error']?.toString() ?? 'Permintaan gagal');
      }
      return map;
    } on DioException catch (e) {
      throw ApiException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Koneksi ke server habis waktu. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      default:
        return 'Terjadi kesalahan saat menghubungi server.';
    }
  }

  /// `GET /health`
  Future<bool> health() async {
    final body = await _get('/health');
    return body['status'] == 'healthy';
  }

  /// `GET /api/prices`
  Future<List<PriceSource>> sources() async {
    final body = await _get('/api/prices');
    final list = (body['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => PriceSource.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `GET /api/prices/:source`
  Future<List<GoldPrice>> prices(String source, {bool refresh = false}) async {
    final body = await _get(
      '/api/prices/$source',
      query: refresh ? {'refresh': 'true'} : null,
    );
    final list = (body['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => GoldPrice.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `GET /api/prices/:source/history`
  Future<HistoryPage> history(
    String source, {
    int page = 1,
    int length = 100,
    num? weight,
    String? material,
    String? materialType,
  }) async {
    final body = await _get(
      '/api/prices/$source/history',
      query: {
        'page': page,
        'length': length,
        'weight': ?weight,
        'material': ?material,
        'materialType': ?materialType,
      },
    );
    final list = (body['data'] as List?) ?? const [];
    final pagination = (body['pagination'] as Map?) ?? const {};
    return HistoryPage(
      items: list
          .whereType<Map>()
          .map((e) => GoldPrice.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: (pagination['page'] as num?)?.toInt() ?? page,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  /// `GET /api/news/investor-id`
  Future<List<NewsItem>> news() async {
    final body = await _get('/api/news/investor-id');
    final list = (body['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `GET /api/news/investor-id/detail?url=`
  Future<NewsDetail> newsDetail(String url) async {
    final body = await _get(
      '/api/news/investor-id/detail',
      query: {'url': url},
    );
    final data = body['data'];
    if (data is! Map) {
      throw ApiException('Detail berita tidak tersedia.');
    }
    return NewsDetail.fromJson(Map<String, dynamic>.from(data));
  }
}
