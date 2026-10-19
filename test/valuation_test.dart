import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// `v` has a buyback price, `nb` (no-buyback) only has a selling price.
class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    String body;
    if (path == '/api/prices') {
      body =
          '{"data":[{"name":"v","displayName":"V"},{"name":"nb","displayName":"NB"}]}';
    } else if (path == '/api/prices/v') {
      body =
          '{"success":true,"data":['
          '{"source":"v","material":"gold","materialType":"A","weight":1,"sellPrice":2500000,"buybackPrice":2400000,"currency":"IDR","recordedDate":"2026-10-15"}'
          ']}';
    } else {
      body =
          '{"success":true,"data":['
          '{"source":"nb","material":"gold","materialType":"B","weight":1,"sellPrice":2500000,"buybackPrice":null,"currency":"IDR","recordedDate":"2026-10-15"}'
          ']}';
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PriceController _controller() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = _Adapter();
  return PriceController(ApiClient(dio: dio));
}

void main() {
  test('valuation uses the buyback price, not the selling price', () async {
    final price = _controller();
    await price.load();
    expect(price.buybackPerGram('v'), 2400000);
    expect(price.valuationPerGram('v'), 2400000);
  });

  test(
    'valuation falls back to selling price when buyback is missing',
    () async {
      final price = _controller();
      await price.load();
      expect(price.buybackPerGram('nb'), isNull);
      expect(price.valuationPerGram('nb'), 2500000);
    },
  );
}
