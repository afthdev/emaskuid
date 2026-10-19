import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emaskuid/controllers/news_controller.dart';
import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:emaskuid/data/local/prefs_store.dart';
import 'package:emaskuid/screens/compare/compare_page.dart';
import 'package:emaskuid/screens/market/market_page.dart';
import 'package:emaskuid/screens/news/news_page.dart';
import 'package:emaskuid/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves canned JSON so the network-driven screens can be rendered offline.
class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    return ResponseBody.fromString(
      _bodyFor(path),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  String _bodyFor(String path) {
    if (path == '/api/prices') {
      return '{"data":['
          '{"name":"alpha","displayName":"Alpha Gold","url":"/api/prices/alpha"},'
          '{"name":"beta","displayName":"Beta Emas","url":"/api/prices/beta"}'
          ']}';
    }
    if (path.endsWith('/history')) {
      return '{"success":true,"data":['
          '{"source":"alpha","material":"gold","materialType":"ANTAM","weight":1,"weightUnit":"gr","sellPrice":1010000,"buybackPrice":960000,"currency":"IDR","recordedDate":"2026-10-15"},'
          '{"source":"alpha","material":"gold","materialType":"ANTAM","weight":1,"weightUnit":"gr","sellPrice":1005000,"buybackPrice":955000,"currency":"IDR","recordedDate":"2026-10-14"},'
          '{"source":"alpha","material":"gold","materialType":"ANTAM","weight":1,"weightUnit":"gr","sellPrice":1000000,"buybackPrice":950000,"currency":"IDR","recordedDate":"2026-10-13"}'
          '],"pagination":{"page":1,"length":200,"total":3,"totalPages":1}}';
    }
    if (path == '/api/news/investor-id') {
      return '{"success":true,"data":['
          '{"title":"Harga Emas Naik Hari Ini","url":"https://x/1","publishedAt":"1 jam yang lalu","summary":"Emas menguat.","category":"Market","displayName":"Investor.id"}'
          '],"source":"investor-id"}';
    }
    // /api/prices/:source
    if (path == '/api/prices/alpha') {
      return '{"success":true,"data":['
          '{"source":"alpha","material":"gold","materialType":"ANTAM","weight":1,"weightUnit":"gr","sellPrice":1010000,"buybackPrice":960000,"currency":"IDR","recordedDate":"2026-10-15"},'
          '{"source":"alpha","material":"gold","materialType":"ANTAM","weight":5,"weightUnit":"gr","sellPrice":5000000,"buybackPrice":4800000,"currency":"IDR","recordedDate":"2026-10-15"}'
          ']}';
    }
    if (path == '/api/prices/beta') {
      return '{"success":true,"data":['
          '{"source":"beta","material":"gold","materialType":"UBS","weight":1,"weightUnit":"gr","sellPrice":990000,"buybackPrice":965000,"currency":"IDR","recordedDate":"2026-10-15"}'
          ']}';
    }
    return '{"success":true,"data":[]}';
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _fakeApi() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.httpClientAdapter = _FakeAdapter();
  return ApiClient(dio: dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    await initializeDateFormatting('id_ID');
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefsStore.init();
    Get.put(prefs);
    Get.put(WatchlistController(prefs));
  });

  tearDown(Get.reset);

  testWidgets('market lists vendors with 1gr price', (tester) async {
    Get.put(PriceController(_fakeApi()));
    await tester.pumpWidget(const GetMaterialApp(home: MarketPage()));
    await _settle(tester);

    expect(find.text('Alpha Gold'), findsOneWidget);
    expect(find.text('Beta Emas'), findsOneWidget);
    expect(find.textContaining('1 gr'), findsWidgets);
  });

  testWidgets('sensitive price is masked when privacy is on', (tester) async {
    Get.put(PrivacyController(Get.find<PrefsStore>()));
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(body: PriceText('Rp1.000', sensitive: true)),
      ),
    );
    expect(find.text('Rp1.000'), findsOneWidget);

    Get.find<PrivacyController>().toggle();
    await tester.pump();

    expect(find.text(PriceText.masked), findsOneWidget);
  });

  testWidgets('bookmark icon updates when tapped', (tester) async {
    Get.put(PriceController(_fakeApi()));
    await tester.pumpWidget(const GetMaterialApp(home: MarketPage()));
    await _settle(tester);

    expect(find.byIcon(Icons.bookmark_border_rounded), findsWidgets);
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded).first);
    await _settle(tester);

    expect(find.byIcon(Icons.bookmark_rounded), findsWidgets);
  });

  testWidgets('compare picks cheapest buy and best buyback', (tester) async {
    Get.put(PriceController(_fakeApi()));
    await tester.pumpWidget(const GetMaterialApp(home: ComparePage()));
    await _settle(tester);

    expect(find.text('Banding Harga'), findsOneWidget);
    expect(find.text('Beli termurah'), findsOneWidget);
    expect(find.text('Beta Emas'), findsWidgets);
  });

  testWidgets('news renders article cards', (tester) async {
    Get.put(NewsController(_fakeApi()));
    await tester.pumpWidget(const GetMaterialApp(home: NewsPage()));
    await _settle(tester);

    expect(find.textContaining('Harga Emas Naik'), findsOneWidget);
  });
}

/// Shimmer/RefreshIndicator keep scheduling frames, so pump a fixed number of
/// frames instead of waiting for a full settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
