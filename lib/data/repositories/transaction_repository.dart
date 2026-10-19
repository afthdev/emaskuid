import 'package:emaskuid/data/local/local_database.dart';
import 'package:emaskuid/data/models/models.dart';

/// CRUD for locally stored savings transactions.
class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  Future<List<Transaction>> all() async {
    final rows = await _db.db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<Transaction> insert(Transaction tx) async {
    final id = await _db.db.insert('transactions', tx.toMap()..remove('id'));
    return tx.copyWith(id: id);
  }

  Future<void> update(Transaction tx) async {
    await _db.db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
