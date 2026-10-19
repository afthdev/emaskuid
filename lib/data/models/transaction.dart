import 'package:emaskuid/data/models/json_utils.dart';
import 'package:emaskuid/data/models/transaction_type.dart';

/// A locally stored savings transaction (buy/sell gold).
class Transaction {
  const Transaction({
    this.id,
    required this.type,
    required this.vendorSource,
    required this.vendorName,
    this.materialType,
    required this.weight,
    required this.pricePerGram,
    required this.date,
    this.note,
  });

  final int? id;
  final TxType type;
  final String vendorSource;
  final String vendorName;
  final String? materialType;

  /// Grams.
  final double weight;

  /// Rupiah per gram.
  final double pricePerGram;
  final DateTime date;
  final String? note;

  double get total => weight * pricePerGram;

  Transaction copyWith({int? id}) => Transaction(
    id: id ?? this.id,
    type: type,
    vendorSource: vendorSource,
    vendorName: vendorName,
    materialType: materialType,
    weight: weight,
    pricePerGram: pricePerGram,
    date: date,
    note: note,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.value,
    'vendor_source': vendorSource,
    'vendor_name': vendorName,
    'material_type': materialType,
    'weight': weight,
    'price_per_gram': pricePerGram,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as int?,
      type: (map['type'] as String?) == 'sell' ? TxType.sell : TxType.buy,
      vendorSource: (map['vendor_source'] as String?) ?? '',
      vendorName: (map['vendor_name'] as String?) ?? '',
      materialType: map['material_type'] as String?,
      weight: asDouble(map['weight']),
      pricePerGram: asDouble(map['price_per_gram']),
      date: DateTime.tryParse((map['date'] as String?) ?? '') ?? DateTime.now(),
      note: map['note'] as String?,
    );
  }
}
