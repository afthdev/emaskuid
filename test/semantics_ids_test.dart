import 'package:emaskuid/controllers/news_controller.dart';
import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:emaskuid/controllers/transaction_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/core/testing/test_ids.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:emaskuid/data/local/local_database.dart';
import 'package:emaskuid/data/local/prefs_store.dart';
import 'package:emaskuid/data/repositories/transaction_repository.dart';
import 'package:emaskuid/screens/shell/main_shell.dart';
import 'package:emaskuid/widgets/async_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

/// Guards the automation ids: every id must resolve exactly once, and no two
/// nodes may share an id (Appium reports an ambiguous match for both).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  setUp(() async {
    Get.reset();
    await initializeDateFormatting('id_ID');
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefsStore.init();
    final db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: ':memory:',
    );
    Get.put(prefs);
    Get.put(WatchlistController(prefs));
    Get.put(PriceController(ApiClient()));
    Get.put(NewsController(ApiClient()));
    Get.put(PrivacyController(prefs));
    Get.put(TransactionController(TransactionRepository(db)));
  });

  tearDown(Get.reset);

  testWidgets('every bottom-navigation tab has a unique id', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const GetMaterialApp(home: MainShell()));
    await _settle(tester);

    for (final id in const [
      TestIds.tabDashboard,
      TestIds.tabMarket,
      TestIds.tabCompare,
      TestIds.tabSavings,
      TestIds.tabNews,
    ]) {
      expect(
        find.bySemanticsIdentifier(id),
        findsOneWidget,
        reason: 'accessibility id (Appium content-desc) missing: $id',
      );
      expect(
        find.byKey(ValueKey(id)),
        findsOneWidget,
        reason: 'widget key (flutter driver byValueKey) missing: $id',
      );
    }

    handle.dispose();
  });

  testWidgets('tapping a tab by its id switches pages', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const GetMaterialApp(home: MainShell()));
    await _settle(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSavings));
    await _settle(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 3);

    handle.dispose();
  });

  testWidgets('async states are addressable, incl. the retry action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncStateView(
          loading: true,
          hasData: false,
          onRetry: _noop,
          child: SizedBox.shrink(),
        ),
      ),
    );
    expect(find.bySemanticsIdentifier(TestIds.stateLoading), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncStateView(
          loading: false,
          hasData: false,
          error: 'jaringan mati',
          onRetry: _noop,
          child: SizedBox.shrink(),
        ),
      ),
    );
    expect(find.bySemanticsIdentifier(TestIds.stateError), findsOneWidget);
    expect(find.bySemanticsIdentifier(TestIds.actionRetry), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncStateView(
          loading: false,
          hasData: false,
          onRetry: _noop,
          child: SizedBox.shrink(),
        ),
      ),
    );
    expect(find.bySemanticsIdentifier(TestIds.stateEmpty), findsOneWidget);

    handle.dispose();
  });
}

void _noop() {}

/// Shimmer/RefreshIndicator keep scheduling frames, so pump a fixed number of
/// frames instead of waiting for a full settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
