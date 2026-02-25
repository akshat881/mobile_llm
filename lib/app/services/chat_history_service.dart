import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_session.dart';

class ChatHistoryService extends GetxService {
  late Database _db;
  final RxList<ChatSession> sessions = <ChatSession>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initDb();
  }

  Future<void> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'chat_history.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create sessions table
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            title TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            modelId TEXT,
            messageCount INTEGER
          )
        ''');

        // Create messages table
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            sessionId TEXT,
            content TEXT,
            role TEXT,
            timestamp TEXT,
            FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (Database db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    await loadSessions();
  }

  Future<void> loadSessions() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'sessions',
      orderBy: 'updatedAt DESC',
    );
    sessions.value = maps.map((map) => ChatSession.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<ChatSession> createSession(String title, {String? modelId}) async {
    final session = ChatSession(title: title, modelId: modelId);
    await _db.insert('sessions', session.toMap());
    
    // Add to the top of the observable list
    sessions.insert(0, session);
    return session;
  }

  Future<void> saveMessage(String sessionId, ChatMessage message) async {
    await _db.insert('messages', message.toMap(sessionId));
    
    // Update session modification time and message count
    await _db.rawUpdate('''
      UPDATE sessions 
      SET updatedAt = ?, messageCount = messageCount + 1 
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), sessionId]);

    // Refresh the observable list to reflect the updated time
    await loadSessions();
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    await _db.update(
      'sessions',
      {'title': newTitle, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await loadSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    // Foreign keys with CASCADE will auto-delete messages
    await _db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    sessions.removeWhere((s) => s.id == sessionId);
  }

  Future<void> clearAllHistory() async {
    await _db.delete('sessions'); // Also cascades to messages
    sessions.clear();
  }
}
