import 'dart:io';

import 'package:emaskuid/data/local/local_database.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

void main() {
  setUpAll(sqfliteFfiInit);

  test('a transaction survives an app restart (real SQLite file)', () async {
    final dir = await Directory.systemTemp.createTemp('emasku_test');
    final path = '${dir.path}/emasku.db';
    try {
      // First run: user adds a transaction.
      final first = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      await TransactionRepository(first).insert(
        Transaction(
          type: TxType.buy,
          vendorSource: 'logammulia',
          vendorName: 'Logam Mulia',
          weight: 2,
          pricePerGram: 1000000,
          date: DateTime(2026, 10, 1),
          note: 'cicilan pertama',
        ),
      );
      await first.db.close();

      // Second run: fresh open reads the same file.
      final second = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final rows = await TransactionRepository(second).all();
      expect(rows, hasLength(1));
      expect(rows.first.weight, 2);
      expect(rows.first.vendorName, 'Logam Mulia');
      expect(rows.first.note, 'cicilan pertama');
      await second.db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
