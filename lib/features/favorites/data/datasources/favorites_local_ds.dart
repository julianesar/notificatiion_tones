import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/favorite_model.dart';

abstract class FavoritesLocalDS {
  Future<List<FavoriteModel>> getAllFavorites();
  Future<void> addFavorite(FavoriteModel favorite);
  Future<void> removeFavorite(String toneId);
  Future<bool> isFavorite(String toneId);
  Future<void> clearAllFavorites();
}

class FavoritesLocalDSImpl implements FavoritesLocalDS {
  static const String _tableName = 'favorites';
  static const String _databaseName = 'favorites.db';
  static const int _databaseVersion = 2;
  
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        tone_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        requires_attribution INTEGER NOT NULL DEFAULT 0,
        attribution_text TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $_tableName ADD COLUMN requires_attribution INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE $_tableName ADD COLUMN attribution_text TEXT
      ''');
    }
  }

  @override
  Future<List<FavoriteModel>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return FavoriteModel.fromMap(maps[i]);
    });
  }

  @override
  Future<void> addFavorite(FavoriteModel favorite) async {
    final db = await database;
    await db.insert(
      _tableName,
      favorite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeFavorite(String toneId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'tone_id = ?',
      whereArgs: [toneId],
    );
  }

  @override
  Future<bool> isFavorite(String toneId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'tone_id = ?',
      whereArgs: [toneId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  @override
  Future<void> clearAllFavorites() async {
    final db = await database;
    await db.delete(_tableName);
  }
}