// note_model.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime creationTime;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.creationTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'creationTime': creationTime.toIso8601String(),
    };
  }

  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      creationTime: DateTime.parse(map['creationTime'] as String),
    );
  }

  // Extension to allow copying with new ID after insertion
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? creationTime,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      creationTime: creationTime ?? this.creationTime,
    );
  }
}

class NoteDatabase {
  static final NoteDatabase instance = NoteDatabase._init();
  static Database? _database;
  NoteDatabase._init();

  final String tableName = 'notes';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE $tableName ( 
        id $idType, 
        title $textType,
        content $textType,
        creationTime $textType
      )
    ''');
  }

  Future<Note> create(Note note) async {
    final db = await instance.database;
    final id = await db.insert(tableName, note.toMap());
    return note.copyWith(id: id);
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    const orderBy = 'creationTime DESC';
    final result = await db.query(tableName, orderBy: orderBy);

    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;
    return db.update(
      tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
