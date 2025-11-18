import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// Manages all database interactions for the Bible app (verses, bookmarks, highlights).
class BibleDatabase {
  Database? _db;

  Database get db => _db!;
  bool get isReady => _db != null;

  // Database initialization and table creation
  Future<void> initDb() async {
    // Note: getApplicationDocumentsDirectory is for Flutter environment
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bible_app.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            version TEXT,
            book TEXT,
            chapter INTEGER,
            verse INTEGER,
            text TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE,
            version TEXT,
            book TEXT,
            chapter INTEGER,
            verse INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE highlights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE,
            version TEXT,
            book TEXT,
            chapter INTEGER,
            verse INTEGER,
            color TEXT
          );
        ''');
        // Add index for faster verse lookups
        await db.execute(
          'CREATE INDEX idx_verses_lookup ON verses (version, book, chapter)',
        );
      },
    );
  }

  // MARK: - Verse Operations

  Future<List<Map<String, dynamic>>> loadChapter(
    String version,
    String book,
    int chapter,
  ) async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'verses',
      where: 'version = ? AND book = ? AND chapter = ?',
      whereArgs: [version, book, chapter],
      orderBy: 'verse ASC',
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (_db == null) return [];
    final q = '%${query.toLowerCase()}%';
    final rows = await _db!.rawQuery(
      '''
      SELECT version, book, chapter, verse, text FROM verses
      WHERE LOWER(text) LIKE ?
      ORDER BY book, chapter, verse
      LIMIT 200
    ''',
      [q],
    );
    return rows;
  }

  // daily verse: pick a random verse from the selected version
  Future<Map<String, dynamic>?> dailyVerse(String version) async {
    if (_db == null) return null;
    final countRow = await _db!.rawQuery(
      'SELECT COUNT(*) as c FROM verses WHERE version = ?',
      [version],
    );
    final count = Sqflite.firstIntValue(countRow) ?? 0;
    if (count == 0) return null;
    final randIndex = Random().nextInt(count);
    final rows = await _db!.rawQuery(
      'SELECT version,book,chapter,verse,text FROM verses WHERE version = ? LIMIT 1 OFFSET ?',
      [version, randIndex],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // MARK: - Bookmarks & Highlights Operations

  Future<Set<String>> loadBookmarks() async {
    if (_db == null) return {};
    final bm = await _db!.query('bookmarks');
    return bm.map((r) => r['key'].toString()).toSet();
  }

  Future<Set<String>> loadHighlights() async {
    if (_db == null) return {};
    final hl = await _db!.query('highlights');
    return hl.map((r) => r['key'].toString()).toSet();
  }

  Future<void> toggleBookmark(
    String key,
    String version,
    String book,
    int chapter,
    int verse,
    bool isBookmarked,
  ) async {
    if (_db == null) return;
    if (isBookmarked) {
      await _db!.delete('bookmarks', where: 'key = ?', whereArgs: [key]);
    } else {
      // Note: text field is omitted as per the new table structure
      await _db!.insert('bookmarks', {
        'key': key,
        'version': version,
        'book': book,
        'chapter': chapter,
        'verse': verse,
      });
    }
  }

  Future<void> toggleHighlight(
    String key,
    String version,
    String book,
    int chapter,
    int verse,
    bool isHighlighted,
  ) async {
    if (_db == null) return;
    if (isHighlighted) {
      await _db!.delete('highlights', where: 'key = ?', whereArgs: [key]);
    } else {
      // Note: text field is omitted as per the new table structure
      await _db!.insert('highlights', {
        'key': key,
        'version': version,
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'color': '#FFF59D', // pale yellow default
      });
    }
  }

  Future<List<Map<String, dynamic>>> getAllBookmarks() async {
    if (_db == null) return [];
    return await _db!.query('bookmarks', orderBy: 'id DESC');
  }

  // MARK: - Downloader/Maintenance Operations

  /// Deletes all verses, bookmarks, and highlights associated with a specific version.
  /// Returns a list of keys deleted from bookmarks/highlights to update local state.
  Future<List<String>> deleteVersion(String version) async {
    if (_db == null) return [];

    final List<String> deletedKeys = [];

    // Use a transaction for atomic deletion
    await _db!.transaction((txn) async {
      // 1. Delete all verses for the version
      await txn.delete('verses', where: 'version = ?', whereArgs: [version]);

      // 2. Query bookmarks/highlights keys before deleting (to update UI state later)
      // We use raw query/LIKE for pattern matching keys (e.g., 'niv|Genesis|1|1')
      final bookmarkKeys = await txn.query(
        'bookmarks',
        where: "key LIKE '$version|%'",
        columns: ['key'],
      );
      final highlightKeys = await txn.query(
        'highlights',
        where: "key LIKE '$version|%'",
        columns: ['key'],
      );

      // Collect keys to remove from the calling widget's in-memory state
      deletedKeys.addAll(bookmarkKeys.map((e) => e['key'].toString()));
      deletedKeys.addAll(highlightKeys.map((e) => e['key'].toString()));

      // 3. Delete bookmarks/highlights associated with this version
      await txn.delete('bookmarks', where: "key LIKE '$version|%'");
      await txn.delete('highlights', where: "key LIKE '$version|%'");
    });

    return deletedKeys;
  }

  // Used by downloader to save fetched verses
  Batch getBatch() => _db!.batch();

  Future<void> commitBatch(Batch batch) => batch.commit(noResult: true);
}
