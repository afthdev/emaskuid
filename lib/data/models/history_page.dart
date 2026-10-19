import 'package:emaskuid/data/models/gold_price.dart';

/// Paginated payload of `/api/prices/:source/history`.
class HistoryPage {
  const HistoryPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<GoldPrice> items;
  final int page;
  final int totalPages;
}
