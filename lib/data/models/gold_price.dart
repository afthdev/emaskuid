import 'package:emaskuid/data/models/json_utils.dart';

/// One price row from `/api/prices/:source` or its `/history`.
class GoldPrice {
  const GoldPrice({
    required this.source,
    required this.material,
    required this.materialType,
    required this.weight,
    required this.weightUnit,
    this.sellPrice,
    this.buybackPrice,
    required this.currency,
    required this.recordedDate,
    this.createdAt,
    this.displayName = '',
    this.favicon,
    this.urlHomepage,
  });

  final String source;
  final String material;
  final String materialType;
  final double weight;
  final String weightUnit;
  final double? sellPrice;
  final double? buybackPrice;
  final String currency;
  final String recordedDate;
  final String? createdAt;
  final String displayName;
  final String? favicon;
  final String? urlHomepage;

  bool get isGold => material.toLowerCase() == 'gold';

  /// Round-trip cost when buying then selling back to the same toko.
  double? get spread {
    if (sellPrice == null || buybackPrice == null) return null;
    return sellPrice! - buybackPrice!;
  }

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      source: asString(json['source']),
      material: asString(json['material'], 'gold'),
      materialType: asString(json['materialType']),
      weight: asDouble(json['weight']),
      weightUnit: asString(json['weightUnit'], 'gr'),
      sellPrice: asPositiveOrNull(json['sellPrice']),
      buybackPrice: asPositiveOrNull(json['buybackPrice']),
      currency: asString(json['currency'], 'IDR'),
      recordedDate: asString(json['recordedDate']),
      createdAt: json['createdAt']?.toString(),
      displayName: asString(json['displayName']),
      favicon: json['favicon']?.toString(),
      urlHomepage: json['urlHomepage']?.toString(),
    );
  }
}
