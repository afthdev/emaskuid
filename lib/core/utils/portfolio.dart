import 'package:emaskuid/data/models/models.dart';

/// Pure portfolio math over a list of transactions. No Flutter, no DB — testable.
class Portfolio {
  const Portfolio(this.transactions);

  final List<Transaction> transactions;

  Iterable<Transaction> get _buys =>
      transactions.where((t) => t.type == TxType.buy);
  Iterable<Transaction> get _sells =>
      transactions.where((t) => t.type == TxType.sell);

  /// Grams currently held.
  double get gramsHeld => transactions.fold(
    0,
    (sum, t) => sum + (t.type == TxType.buy ? t.weight : -t.weight),
  );

  double get totalBuyWeight => _buys.fold(0, (s, t) => s + t.weight);

  double get totalBuyCost => _buys.fold(0, (s, t) => s + t.total);

  double get totalSellProceeds => _sells.fold(0, (s, t) => s + t.total);

  double get avgBuyPrice =>
      totalBuyWeight == 0 ? 0 : totalBuyCost / totalBuyWeight;

  /// Cash still tied up in gold (buys minus anything already sold).
  double get netInvested => totalBuyCost - totalSellProceeds;

  double portfolioValue(double pricePerGram) => gramsHeld * pricePerGram;

  double unrealized(double pricePerGram) =>
      portfolioValue(pricePerGram) - netInvested;

  double unrealizedPercent(double pricePerGram) {
    if (netInvested == 0) return 0;
    return unrealized(pricePerGram) / netInvested * 100;
  }
}
