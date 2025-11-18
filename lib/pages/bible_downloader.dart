// lib/services/bible_downloader.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'bible_db.dart'; // Update your app name here

/// Manages the one-time download of a Bible version from bible-api.com.
class BibleDownloader {
  final BibleDatabase db;
  final SharedPreferences prefs;

  // State to be managed by the calling class (e.g., _BiblePageState)
  final Function(int downloaded, int total) onProgressUpdate;
  final Function(bool isDownloading) onDownloadStateChanged;

  BibleDownloader({
    required this.db,
    required this.prefs,
    required this.onProgressUpdate,
    required this.onDownloadStateChanged,
  });

  bool _cancelDownload = false;

  // approximate max chapters per book (moved from BiblePage state)
  final Map<String, int> approxMaxChapters = {
    'Genesis': 50,
    'Exodus': 40,
    'Leviticus': 27,
    'Numbers': 36,
    'Deuteronomy': 34,
    'Joshua': 24,
    'Judges': 21,
    'Ruth': 4,
    '1 Samuel': 31,
    '2 Samuel': 24,
    '1 Kings': 22,
    '2 Kings': 25,
    '1 Chronicles': 29,
    '2 Chronicles': 36,
    'Ezra': 10,
    'Nehemiah': 13,
    'Esther': 10,
    'Job': 42,
    'Psalms': 150,
    'Proverbs': 31,
    'Ecclesiastes': 12,
    'Song of Solomon': 8,
    'Isaiah': 66,
    'Jeremiah': 52,
    'Lamentations': 5,
    'Ezekiel': 48,
    'Daniel': 12,
    'Hosea': 14,
    'Joel': 3,
    'Amos': 9,
    'Obadiah': 1,
    'Jonah': 4,
    'Micah': 7,
    'Nahum': 3,
    'Habakkuk': 3,
    'Zephaniah': 3,
    'Haggai': 2,
    'Zechariah': 14,
    'Malachi': 4,
    'Matthew': 28,
    'Mark': 16,
    'Luke': 24,
    'John': 21,
    'Acts': 28,
    'Romans': 16,
    '1 Corinthians': 16,
    '2 Corinthians': 13,
    'Galatians': 6,
    'Ephesians': 6,
    'Philippians': 4,
    'Colossians': 4,
    '1 Thessalonians': 5,
    '2 Thessalonians': 3,
    '1 Timothy': 6,
    '2 Timothy': 4,
    'Titus': 3,
    'Philemon': 1,
    'Hebrews': 13,
    'James': 5,
    '1 Peter': 5,
    '2 Peter': 3,
    '1 John': 5,
    '2 John': 1,
    '3 John': 1,
    'Jude': 1,
    'Revelation': 22,
  };

  final List<String> books = [
    'Genesis',
    'Exodus',
    'Leviticus',
    'Numbers',
    'Deuteronomy',
    'Joshua',
    'Judges',
    'Ruth',
    '1 Samuel',
    '2 Samuel',
    '1 Kings',
    '2 Kings',
    '1 Chronicles',
    '2 Chronicles',
    'Ezra',
    'Nehemiah',
    'Esther',
    'Job',
    'Psalms',
    'Proverbs',
    'Ecclesiastes',
    'Song of Solomon',
    'Isaiah',
    'Jeremiah',
    'Lamentations',
    'Ezekiel',
    'Daniel',
    'Hosea',
    'Joel',
    'Amos',
    'Obadiah',
    'Jonah',
    'Micah',
    'Nahum',
    'Habakkuk',
    'Zephaniah',
    'Haggai',
    'Zechariah',
    'Malachi',
    'Matthew',
    'Mark',
    'Luke',
    'John',
    'Acts',
    'Romans',
    '1 Corinthians',
    '2 Corinthians',
    'Galatians',
    'Ephesians',
    'Philippians',
    'Colossians',
    '1 Thessalonians',
    '2 Thessalonians',
    '1 Timothy',
    '2 Timothy',
    'Titus',
    'Philemon',
    'Hebrews',
    'James',
    '1 Peter',
    '2 Peter',
    '1 John',
    '2 John',
    '3 John',
    'Jude',
    'Revelation',
  ];

  Future<bool> isVersionDownloaded(String version) async {
    final key = 'bible_downloaded_$version';
    return prefs.getBool(key) ?? false;
  }

  Future<void> _markVersionDownloaded(String version, bool value) async {
    final key = 'bible_downloaded_$version';
    await prefs.setBool(key, value);
  }

  /// Downloads all books and chapters for a particular [version].
  Future<void> downloadVersion(String version) async {
    if (!db.isReady) return;

    _cancelDownload = false;
    onDownloadStateChanged(true); // Signal start

    int downloadedChapters = 0;
    final totalChaptersToDownload = books.fold<int>(
      0,
      (prev, b) => prev + (approxMaxChapters[b] ?? 1),
    );

    onProgressUpdate(0, totalChaptersToDownload); // Initial progress

    try {
      for (final book in books) {
        final maxTry = approxMaxChapters[book] ?? 150;
        for (int chap = 1; chap <= maxTry; chap++) {
          if (_cancelDownload) break;

          final ok = await _fetchAndStoreChapter(version, book, chap);
          if (!ok) {
            // assume chapter does not exist and break inner loop
            break;
          }
          downloadedChapters++;
          onProgressUpdate(downloadedChapters, totalChaptersToDownload);
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (_cancelDownload) break;
      }

      if (!_cancelDownload) {
        await _markVersionDownloaded(version, true);
      }
    } finally {
      onDownloadStateChanged(false); // Signal end
    }
  }

  void cancelActiveDownload() {
    _cancelDownload = true;
  }

  /// Fetch a chapter via bible-api.com and insert verses to DB.
  Future<bool> _fetchAndStoreChapter(
    String version,
    String book,
    int chapter,
  ) async {
    try {
      final q = Uri.encodeComponent('$book $chapter');
      final uri = Uri.parse(
        'https://bible-api.com/$q?translation=${Uri.encodeComponent(version)}',
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return false;
      }
      final Map<String, dynamic> data = jsonDecode(resp.body);
      if (data['verses'] == null) return false;
      final versesData = (data['verses'] as List<dynamic>);

      final batch = db.getBatch();
      for (var v in versesData) {
        final verseNum = v['verse'] ?? v['verse_number'] ?? 0;
        final text = (v['text'] ?? '').toString().trim();
        batch.insert('verses', {
          'version': version,
          'book': v['book_name'] ?? book,
          'chapter': v['chapter'] ?? chapter,
          'verse': verseNum,
          'text': text,
        });
      }
      await db.commitBatch(batch);
      return true;
    } catch (e) {
      return false;
    }
  }
}
