import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_app/models/chat_models.dart';
import 'dart:async';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'solobudd_chat.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create conversations table
    await db.execute('''
      CREATE TABLE conversations(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        last_message_text TEXT,
        last_message_time TEXT,
        type TEXT NOT NULL,
        image_url TEXT,
        is_unread INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create participants table
    await db.execute('''
      CREATE TABLE participants(
        conversation_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        joined_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (conversation_id, user_id),
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        reply_to_id TEXT,
        attachment_url TEXT,
        attachment_type TEXT,
        is_synced INTEGER NOT NULL DEFAULT 1,
        is_pending INTEGER NOT NULL DEFAULT 0,
        is_failed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
        FOREIGN KEY (reply_to_id) REFERENCES messages(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)');
    await db.execute('CREATE INDEX idx_participants_conversation_id ON participants(conversation_id)');
    await db.execute('CREATE INDEX idx_participants_user_id ON participants(user_id)');
  }

  // Conversation methods
  Future<List<ChatConversation>> getConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('conversations', orderBy: 'updated_at DESC');
    return List.generate(maps.length, (i) => ChatConversation.fromMap(maps[i]));
  }

  Future<ChatConversation?> getConversation(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ChatConversation.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertConversation(ChatConversation conversation) async {
    final db = await database;
    await db.insert(
      'conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateConversation(ChatConversation conversation) async {
    final db = await database;
    await db.update(
      'conversations',
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Participant methods
  Future<List<ChatParticipant>> getParticipants(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'participants',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
    return List.generate(maps.length, (i) => ChatParticipant.fromMap(maps[i]));
  }

  Future<void> insertParticipant(ChatParticipant participant) async {
    final db = await database;
    await db.insert(
      'participants',
      participant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteParticipant(String conversationId, String userId) async {
    final db = await database;
    await db.delete(
      'participants',
      where: 'conversation_id = ? AND user_id = ?',
      whereArgs: [conversationId, userId],
    );
  }

  // Message methods
  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessage(ChatMessage message) async {
    final db = await database;
    await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'conversation_id = ? AND is_read = 0',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync methods
  Future<List<ChatConversation>> getUnsyncedConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => ChatConversation.fromMap(maps[i]));
  }

  Future<List<ChatParticipant>> getUnsyncedParticipants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'participants',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => ChatParticipant.fromMap(maps[i]));
  }

  Future<List<ChatMessage>> getUnsyncedMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'is_synced = ? AND is_pending = ? AND is_failed = ?',
      whereArgs: [0, 0, 0],
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<List<ChatMessage>> getPendingMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'is_pending = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<void> markAsSynced(String table, String idField, String id) async {
    final db = await database;
    await db.update(
      table,
      {'is_synced': 1},
      where: '$idField = ?',
      whereArgs: [id],
    );
  }

  Future<void> markMessageAsFailed(String id) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_pending': 0, 'is_failed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markMessageAsPending(String id) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_pending': 1, 'is_failed': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('participants');
    await db.delete('conversations');
  }
}
