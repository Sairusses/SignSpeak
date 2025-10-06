import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'history_item.dart';

class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        gifPath TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(HistoryItem item) async {
    final db = await instance.database;
    return await db.insert('history', item.toMap());
  }

  Future<HistoryItem?> getByText(String text) async {
    final db = await instance.database;
    final result = await db.query(
      'history',
      where: 'text = ?',
      whereArgs: [text],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return HistoryItem.fromMap(result.first);
    } else {
      return null;
    }
  }


  Future<List<HistoryItem>> fetchAll() async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'id DESC');
    return result.map((map) => HistoryItem.fromMap(map)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
