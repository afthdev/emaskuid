import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (and migrates) the local SQLite database.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _name = 'emasku.db';
  static const _version = 1;

  /// [factory] and [path] are injectable so tests can use an in-memory DB.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), _name);
    final db = await (factory ?? databaseFactory).openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              vendor_source TEXT NOT NULL,
              vendor_name TEXT NOT NULL,
              material_type TEXT,
              weight REAL NOT NULL,
              price_per_gram REAL NOT NULL,
              date TEXT NOT NULL,
              note TEXT
            )
          ''');
          await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
        },
      ),
    );
    return AppDatabase._(db);
  }
}
