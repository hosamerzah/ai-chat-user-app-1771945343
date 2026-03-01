import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  static Database? _database;

  factory LocalDbService() {
    return _instance;
  }

  LocalDbService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Database db;
    if (kIsWeb) {
      // Initialize web factory
      databaseFactory = databaseFactoryFfiWeb;
      db = await databaseFactory.openDatabase(
        'ai_chat_history.db',
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      String path = join(await getDatabasesPath(), 'ai_chat_history.db');
      db = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    
    // Ensure the default character exists in the DB after initialization
    await _ensureDefaultCharacter(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create the chat sessions table
    await db.execute('''
      CREATE TABLE sessions(
        id TEXT PRIMARY KEY,
        title TEXT,
        characterId TEXT,
        createdAt INTEGER
      )
    ''');

      // Create the messages table
      await db.execute('''
        CREATE TABLE messages(
          id TEXT PRIMARY KEY,
          sessionId TEXT,
          role TEXT,
          content TEXT,
          createdAt INTEGER,
          FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
        )
      ''');

      // Create characters table
      await db.execute('''
        CREATE TABLE characters(
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          systemPrompt TEXT,
          avatarUrl TEXT,
          isDefault INTEGER
        )
      ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE characters(
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          systemPrompt TEXT,
          avatarUrl TEXT,
          isDefault INTEGER
        )
      ''');
    }
  }

  Future<void> _ensureDefaultCharacter(Database db) async {
    const defaultCharId = 'default_ai_assistant';
    final existing = await db.query('characters', where: 'id = ?', whereArgs: [defaultCharId]);
    
    if (existing.isEmpty) {
      await db.insert('characters', {
        'id': defaultCharId,
        'name': 'AI Assistant',
        'description': 'Your helpful default assistant.',
        'systemPrompt': 'You are a helpful, respectful, and honest default AI assistant.',
        'avatarUrl': '',
        'isDefault': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- Character Methods ---
  
  Future<List<Map<String, dynamic>>> getLocalCharacters() async {
    final db = await database;
    return await db.query('characters', orderBy: 'isDefault DESC, name ASC');
  }

  Future<Map<String, dynamic>?> getCharacter(String id) async {
    final db = await database;
    final results = await db.query('characters', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> saveCharacter(Map<String, dynamic> characterData) async {
    final db = await database;
    await db.insert(
      'characters',
      {
        'id': characterData['id'],
        'name': characterData['name'] ?? 'Unknown',
        'description': characterData['description'] ?? '',
        'systemPrompt': characterData['systemPrompt'] ?? '',
        'avatarUrl': characterData['avatarUrl'] ?? '',
        'isDefault': 0, // Characters from remote are not the local default
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Session Methods ---

  Future<String> createSession(String title, String? characterId) async {
    final db = await database;
    final sessionId = '${DateTime.now().millisecondsSinceEpoch}_${(1000 + (double.nan == 0 ? 0 : 0)).hashCode}'; // Simple unique ID
    await db.insert(
      'sessions',
      {
        'id': sessionId,
        'title': title,
        'characterId': characterId ?? '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return sessionId;
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    return await db.query('sessions', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getSession(String id) async {
    final db = await database;
    final results = await db.query('sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // --- Message Methods ---

  Future<String> saveMessage({
    required String sessionId,
    required String role,
    required String content,
  }) async {
    final db = await database;
    final messageId = '${DateTime.now().millisecondsSinceEpoch}_${content.hashCode.abs()}';
    await db.insert(
      'messages',
      {
        'id': messageId,
        'sessionId': sessionId,
        'role': role,
        'content': content,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return messageId;
  }

  Future<List<Map<String, dynamic>>> getMessagesForSession(String sessionId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'createdAt ASC',
    );
  }
  
  // Method to easily convert a SQLite message row into an API-format message
  List<Map<String, String>> formatMessagesForApi(List<Map<String, dynamic>> dbMessages) {
    return dbMessages.map((msg) {
      return {
        "role": msg['role'] as String,
        "content": msg['content'] as String,
      };
    }).toList();
  }
}
