import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed history so `priceOnDate` can be checked without network.
class _HistoryAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    const body =
        '{"success":true,"data":['
        '{"source":"v","material":"gold","materialType":"ANTAM","weight":1,"sellPrice":1010000,"buybackPrice":960000,"currency":"IDR","recordedDate":"2026-10-15"},'
        '{"source":"v","material":"gold","materialType":"ANTAM","weight":1,"sellPrice":1005000,"buybackPrice":955000,"currency":"IDR","recordedDate":"2026-10-14"},'
        '{"source":"v","material":"gold","materialType":"ANTAM","weight":1,"sellPrice":1000000,"buybackPrice":950000,"currency":"IDR","recordedDate":"2026-10-10"}'
        '],"pagination":{"page":1,"length":200,"total":3,"totalPages":1}}';
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
    ..httpClientAdapter = _HistoryAdapter();
  return PriceController(ApiClient(dio: dio));
}

void main() {
  test('exact date returns that day', () async {
    final price = _controller();
    final p = await price.priceOnDate(
      'v',
      weight: 1,
      date: DateTime(2026, 10, 14),
    );
    expect(p?.sellPrice, 1005000);
  });

  test('between dates returns the previous recorded price', () async {
    final price = _controller();
    final p = await price.priceOnDate(
      'v',
      weight: 1,
      date: DateTime(2026, 10, 13),
    );
    expect(p?.sellPrice, 1000000);
    expect(p?.recordedDate, '2026-10-10');
  });

  test('after the newest record returns the newest price', () async {
    final price = _controller();
    final p = await price.priceOnDate(
      'v',
      weight: 1,
      date: DateTime(2026, 10, 20),
    );
    expect(p?.sellPrice, 1010000);
  });

  test('before any record returns null', () async {
    final price = _controller();
    final p = await price.priceOnDate(
      'v',
      weight: 1,
      date: DateTime(2026, 9, 1),
    );
    expect(p, isNull);
  });
}
