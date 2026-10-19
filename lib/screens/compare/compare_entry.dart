import 'package:emaskuid/data/models/models.dart';

/// A toko + its best price row, used by the compare screen.
class CompareEntry {
  CompareEntry(this.source, this.price);

  final PriceSource source;
  final GoldPrice price;
}
