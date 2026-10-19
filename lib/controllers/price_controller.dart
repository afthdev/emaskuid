import 'package:get/get.dart';

import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:emaskuid/data/models/models.dart';

/// Owns all network-backed price data: source list, latest prices, history.
class PriceController extends GetxController {
  PriceController(this._api);

  final ApiClient _api;

  final RxList<PriceSource> sources = <PriceSource>[].obs;
  final RxMap<String, List<GoldPrice>> pricesBySource =
      <String, List<GoldPrice>>{}.obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final RxString lastUpdated = ''.obs;

  final Map<String, List<GoldPrice>> _historyCache = {};
  final RxSet<String> loadingHistory = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool force = false}) async {
    if (loading.value) return;
    loading.value = true;
    error.value = '';

    try {
      if (sources.isEmpty || force) {
        sources.assignAll(await _api.sources());
      }
      final results = await Future.wait(sources.map(_fetchOne));
      final map = <String, List<GoldPrice>>{};
      for (final entry in results) {
        if (entry != null) map[entry.$1] = entry.$2;
      }
      if (map.isNotEmpty) {
        pricesBySource.assignAll(map);
        if (force) _historyCache.clear();
        lastUpdated.value = Fmt.dateTime(DateTime.now());
      } else if (error.value.isEmpty) {
        error.value = 'Data harga tidak tersedia saat ini.';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<(String, List<GoldPrice>)?> _fetchOne(PriceSource source) async {
    try {
      return (source.name, await _api.prices(source.name));
    } catch (_) {
      return null;
    }
  }

  bool get hasData => pricesBySource.isNotEmpty;

  List<GoldPrice> pricesFor(String source) =>
      pricesBySource[source] ?? const [];

  List<GoldPrice> get allPrices =>
      pricesBySource.values.expand((e) => e).toList(growable: false);

  PriceSource? sourceByName(String name) {
    for (final s in sources) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// Best single reference price for a toko, preferring 1 gram of gold.
  GoldPrice? referencePrice(
    String source, {
    num? weight,
    String material = 'gold',
  }) {
    final rows = pricesFor(
      source,
    ).where((p) => p.material.toLowerCase() == material).toList();
    if (rows.isEmpty) return null;
    if (weight != null) {
      final exact = rows.where((p) => p.weight == weight).toList();
      if (exact.isNotEmpty) return _bestRow(exact);
    }
    final oneGram = rows.where((p) => p.weight == 1).toList();
    if (oneGram.isNotEmpty) return _bestRow(oneGram);
    return _bestRow(rows);
  }

  GoldPrice _bestRow(List<GoldPrice> rows) {
    final priced = rows.where((p) => p.sellPrice != null).toList();
    if (priced.isEmpty) return rows.first;
    priced.sort((a, b) => a.sellPrice!.compareTo(b.sellPrice!));
    return priced.first;
  }

  /// What the toko pays you back per gram today (the liquidation price).
  double? buybackPerGram(String source, {String material = 'gold'}) {
    final rows = pricesFor(source)
        .where(
          (p) => p.material.toLowerCase() == material && p.buybackPrice != null,
        )
        .toList();
    if (rows.isEmpty) return null;
    final oneGram = rows.where((p) => p.weight == 1).toList();
    final pool = oneGram.isNotEmpty ? oneGram : rows;
    pool.sort((a, b) => a.weight.compareTo(b.weight));
    return pool.first.buybackPrice;
  }

  /// Price used to value a portfolio: the buyback if available, else the
  /// selling price (so the number is never blank when a toko lacks buyback).
  double? valuationPerGram(String source, {String material = 'gold'}) {
    return buybackPerGram(source, material: material) ??
        referencePrice(source, weight: 1, material: material)?.sellPrice;
  }

  bool isLoadingHistory(String key) => loadingHistory.contains(key);

  /// Latest recorded market price at or before [date] for a toko + weight.
  /// This is what makes a back-dated transaction use the price of that day,
  /// not today's price.
  Future<GoldPrice?> priceOnDate(
    String source, {
    required num weight,
    required DateTime date,
    String material = 'gold',
  }) async {
    final items = await history(source, weight: weight, material: material);
    final day = DateTime(date.year, date.month, date.day);
    DateTime? bestDay;
    GoldPrice? best;
    for (final p in items) {
      final parsed = Fmt.parseDate(p.recordedDate);
      if (parsed == null) continue;
      final priceDay = DateTime(parsed.year, parsed.month, parsed.day);
      if (priceDay.isAfter(day)) continue;
      if (bestDay == null || priceDay.isAfter(bestDay)) {
        bestDay = priceDay;
        best = p;
      } else if (priceDay == bestDay) {
        final bestSell = best?.sellPrice;
        final sell = p.sellPrice;
        if (sell != null && (bestSell == null || sell < bestSell)) best = p;
      }
    }
    return best;
  }

  /// Fetches history for a toko (cached). Returns newest-first, like the API.
  Future<List<GoldPrice>> history(
    String source, {
    num? weight,
    String? material,
    bool force = false,
  }) async {
    final key = '$source|${weight ?? ''}|${material ?? ''}';
    if (!force && _historyCache.containsKey(key)) return _historyCache[key]!;

    loadingHistory.add(key);
    try {
      final page = await _api.history(
        source,
        length: 200,
        weight: weight,
        material: material,
      );
      _historyCache[key] = page.items;
      return page.items;
    } finally {
      loadingHistory.remove(key);
    }
  }
}
