import 'package:emaskuid/core/utils/portfolio.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(TxType type, double weight, double pricePerGram) => Transaction(
  type: type,
  vendorSource: 'v',
  vendorName: 'V',
  weight: weight,
  pricePerGram: pricePerGram,
  date: DateTime(2026, 1, 1),
);

void main() {
  group('Portfolio', () {
    test('empty portfolio is zeroed out', () {
      const p = Portfolio([]);
      expect(p.gramsHeld, 0);
      expect(p.avgBuyPrice, 0);
      expect(p.netInvested, 0);
      expect(p.unrealizedPercent(1000), 0);
    });

    test('holdings = buys minus sells', () {
      final p = Portfolio([
        _tx(TxType.buy, 10, 1_000_000),
        _tx(TxType.sell, 4, 1_100_000),
      ]);
      expect(p.gramsHeld, 6);
    });

    test('average buy price is weight-weighted', () {
      final p = Portfolio([
        _tx(TxType.buy, 1, 1_000_000),
        _tx(TxType.buy, 3, 2_000_000),
      ]);
      expect(p.totalBuyWeight, 4);
      expect(p.totalBuyCost, 7_000_000);
      expect(p.avgBuyPrice, 1_750_000);
    });

    test('net invested nets out sell proceeds', () {
      final p = Portfolio([
        _tx(TxType.buy, 2, 1_000_000),
        _tx(TxType.sell, 1, 1_200_000),
      ]);
      expect(p.totalBuyCost, 2_000_000);
      expect(p.totalSellProceeds, 1_200_000);
      expect(p.netInvested, 800_000);
    });

    test('unrealized gain and percent follow market price', () {
      final p = Portfolio([_tx(TxType.buy, 2, 1_000_000)]);
      // value = 2 * 1.1jt = 2.2jt, invested = 2jt
      expect(p.portfolioValue(1_100_000), 2_200_000);
      expect(p.unrealized(1_100_000), 200_000);
      expect(p.unrealizedPercent(1_100_000), 10);
    });

    test('a transaction entered as a total keeps that total', () {
      // Form input: 10 gr bar priced at Rp24.500.000 total.
      const weight = 10.0;
      const total = 24_500_000.0;
      final tx = _tx(TxType.buy, weight, total / weight);
      expect(tx.total, total);
      expect(Portfolio([tx]).totalBuyCost, total);
    });
  });

  group('GoldPrice', () {
    test('spread is sell minus buyback', () {
      const p = GoldPrice(
        source: 's',
        material: 'gold',
        materialType: 'ANTAM',
        weight: 1,
        weightUnit: 'gr',
        sellPrice: 2_500_000,
        buybackPrice: 2_400_000,
        currency: 'IDR',
        recordedDate: '2026-10-15',
      );
      expect(p.spread, 100_000);
    });

    test('zero price is treated as unavailable, not free', () {
      final p = GoldPrice.fromJson(const {
        'source': 's',
        'material': 'gold',
        'materialType': 'ANTAM',
        'weight': 1,
        'sellPrice': 0,
        'buybackPrice': 0,
      });
      expect(p.sellPrice, isNull);
      expect(p.buybackPrice, isNull);
    });
  });
}
