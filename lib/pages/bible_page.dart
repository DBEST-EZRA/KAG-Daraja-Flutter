// lib/bible_page.dart (FIXED)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

// Import the new files
import 'bible_db.dart'; // Update your app name here
import 'bible_downloader.dart'; // Update your app name here

/// Single-file Bible page that downloads from bible-api.com (one-time per version)
/// and stores verses in sqlite. Minimal external files. Drop into your project and
/// import the widget where you need it.
class BiblePage extends StatefulWidget {
  const BiblePage({Key? key}) : super(key: key);

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  // --- Constants (stay here as they are tightly coupled with the UI/logic)
  final List<String> versions = ['kjv', 'niv', 'esv'];
  final Map<String, String> versionLabels = {
    'kjv': 'KJV',
    'niv': 'NIV',
    'esv': 'ESV',
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

  final Map<String, int> _approxMaxChapters = {
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

  // --- Services
  final BibleDatabase _dbService = BibleDatabase();
  SharedPreferences? _prefs;
  late BibleDownloader _downloader;

  // --- state
  String selectedVersion = 'kjv';
  String selectedBook = 'John';
  int selectedChapter = 1;

  // download state
  bool _isDownloading = false;
  int _downloadedChapters = 0;
  int _totalChaptersToDownload = 0;

  // UI data
  List<Map<String, dynamic>> verses = [];
  List<Map<String, dynamic>> searchResults = [];
  bool _loadingChapter = false;
  String _searchQuery = '';

  // bookmarks/highlights loaded
  Set<String> _bookmarks = {};
  Set<String> _highlights = {};

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    await _dbService.initDb();
    _prefs = await SharedPreferences.getInstance();

    // Initialize Downloader *after* DB and Prefs are ready
    _downloader = BibleDownloader(
      db: _dbService,
      prefs: _prefs!,
      onProgressUpdate: (downloaded, total) {
        // This setState is okay because it's in a callback, not directly in build.
        setState(() {
          _downloadedChapters = downloaded;
          _totalChaptersToDownload = total;
        });
      },
      onDownloadStateChanged: (isDownloading) {
        // This setState is okay because it's in a callback, not directly in build.
        setState(() {
          _isDownloading = isDownloading;
        });
      },
    );

    // Initial load of bookmarks and highlights
    await _loadBookmarksHighlights();

    // Set initial selected book (ensure 'John' exists or pick first)
    if (!books.contains(selectedBook)) {
      selectedBook = books.first;
    }

    // After all initialization, load the first chapter if the version is downloaded.
    // This setState updates the UI after everything is ready.
    // We defer the actual chapter loading until the initial build is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final downloaded = await _downloader.isVersionDownloaded(selectedVersion);
      if (downloaded) {
        await _loadChapter(selectedVersion, selectedBook, selectedChapter);
      } else {
        setState(() {}); // Update UI to show "Download" button
      }
    });
  }

  Future<void> _loadBookmarksHighlights() async {
    _bookmarks = await _dbService.loadBookmarks();
    _highlights = await _dbService.loadHighlights();
    // No need to call setState here as _initializeEverything calls it once at the end
    // or this method will be called again after a bookmark/highlight change.
  }

  String _keyFor(String version, String book, int chapter, int verse) =>
      '$version|$book|$chapter|$verse';

  // Check if a version was fully downloaded.
  Future<bool> _isVersionDownloaded(String version) =>
      _downloader.isVersionDownloaded(version);

  // ---------- downloader logic (delegated) ----------
  Future<void> _startDownload(String version) async {
    await _downloader.downloadVersion(version);
    // After download completes, reload the chapter to ensure UI is updated
    final downloaded = await _downloader.isVersionDownloaded(version);
    if (downloaded) {
      await _loadChapter(version, selectedBook, selectedChapter);
    }
  }

  void _cancelActiveDownload() {
    _downloader.cancelActiveDownload();
    // No need to wait for a delay since the flag is checked in the loop
  }

  // ---------- reading & searching (delegated) ----------
  Future<void> _loadChapter(String version, String book, int chapter) async {
    // Only update loading state if the actual chapter loading starts
    if (!_loadingChapter) {
      setState(() {
        _loadingChapter = true;
      });
    }

    verses = await _dbService.loadChapter(version, book, chapter);

    setState(() {
      _loadingChapter = false;
    });
  }

  Future<void> _search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      searchResults = [];
      setState(() {});
      return;
    }
    searchResults = await _dbService.search(query);
    setState(() {});
  }

  // daily verse: pick a random verse from the selected version (if downloaded)
  Future<Map<String, dynamic>?> _dailyVerse(String version) =>
      _dbService.dailyVerse(version);

  // ---------- bookmarks & highlights (delegated) ----------
  Future<void> _toggleBookmark(
    String version,
    String book,
    int chapter,
    int verse,
  ) async {
    final key = _keyFor(version, book, chapter, verse);
    final isBookmarked = _bookmarks.contains(key);

    await _dbService.toggleBookmark(
      key,
      version,
      book,
      chapter,
      verse,
      isBookmarked,
    );

    // Update local state
    setState(() {
      isBookmarked ? _bookmarks.remove(key) : _bookmarks.add(key);
    });
  }

  Future<void> _toggleHighlight(
    String version,
    String book,
    int chapter,
    int verse,
  ) async {
    final key = _keyFor(version, book, chapter, verse);
    final isHighlighted = _highlights.contains(key);

    await _dbService.toggleHighlight(
      key,
      version,
      book,
      chapter,
      verse,
      isHighlighted,
    );

    // Update local state
    setState(() {
      isHighlighted ? _highlights.remove(key) : _highlights.add(key);
    });
  }

  // share verse text
  void _shareVerse(
    String book,
    int chapter,
    int verse,
    String text,
    String version,
  ) {
    final payload = '$book $chapter:$verse (${version.toUpperCase()})\n\n$text';
    Share.share(payload);
  }

  // quick UI helper: show snackbar
  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  // ---------- UI (remains in this file) ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        backgroundColor: Colors.blue.shade800, // App bar color
        actions: [
          IconButton(
            tooltip: 'Bookmarks',
            onPressed: _openBookmarks,
            icon: const Icon(Icons.bookmark),
          ),
          IconButton(
            tooltip: 'Daily Verse',
            onPressed: _showDailyVerse,
            icon: const Icon(Icons.wb_sunny),
          ),
        ],
      ),
      body: _dbService.isReady
          ? _buildBody()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // top controls: version, book, chapter, download
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
          child: Row(
            children: [
              // version picker
              DropdownButton<String>(
                value: selectedVersion,
                items: versions
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(versionLabels[v] ?? v.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  selectedVersion = v;
                  setState(() {}); // Update UI immediately for selectedVersion
                  final downloaded = await _isVersionDownloaded(v);
                  if (downloaded) {
                    await _loadChapter(v, selectedBook, selectedChapter);
                  } else {
                    _snack(
                      '${versionLabels[v]} not downloaded. Tap DOWNLOAD to fetch.',
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              // book picker
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedBook,
                  items: books
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (b) async {
                    if (b == null) return;
                    selectedBook = b;
                    selectedChapter = 1; // Reset chapter when book changes
                    setState(
                      () {},
                    ); // Update UI immediately for selectedBook/Chapter
                    if (await _isVersionDownloaded(selectedVersion)) {
                      await _loadChapter(
                        selectedVersion,
                        selectedBook,
                        selectedChapter,
                      );
                    } else {
                      _snack(
                        '${versionLabels[selectedVersion]} not downloaded. Tap DOWNLOAD to fetch.',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // chapter picker
              DropdownButton<int>(
                value: selectedChapter,
                items:
                    List.generate(
                          _approxMaxChapters[selectedBook] ?? 50,
                          (i) => i + 1,
                        )
                        .map(
                          (c) => DropdownMenuItem(value: c, child: Text('$c')),
                        )
                        .toList(),
                onChanged: (c) async {
                  if (c == null) return;
                  selectedChapter = c;
                  setState(() {}); // Update UI immediately for selectedChapter
                  if (await _isVersionDownloaded(selectedVersion)) {
                    await _loadChapter(
                      selectedVersion,
                      selectedBook,
                      selectedChapter,
                    );
                  } else {
                    _snack(
                      '${versionLabels[selectedVersion]} not downloaded. Tap DOWNLOAD.',
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              // download button or downloaded indicator
              FutureBuilder<bool>(
                future: _isVersionDownloaded(selectedVersion),
                builder: (context, snap) {
                  final downloaded = snap.data ?? false;

                  if (_isDownloading && selectedVersion == selectedVersion) {
                    // show progress if currently downloading THIS version
                    final progress = _totalChaptersToDownload > 0
                        ? (_downloadedChapters / _totalChaptersToDownload)
                        : 0.0;
                    return Row(
                      mainAxisSize: MainAxisSize.min, // Keep row compact
                      children: [
                        SizedBox(
                          width: 100, // Adjusted width for progress bar
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.orange.shade100, // Orange background
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange.shade700,
                            ), // Orange progress
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cancel Download',
                          onPressed: _cancelActiveDownload,
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.orange,
                          ), // Orange cancel icon
                        ),
                      ],
                    );
                  }

                  if (downloaded) {
                    return Chip(
                      label: const Text('Downloaded'),
                      backgroundColor:
                          Colors.blue.shade100, // Blue chip for downloaded
                      labelStyle: TextStyle(color: Colors.blue.shade800),
                    );
                  }

                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue.shade700, // Blue download button
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Download for offline use?'),
                          content: Text(
                            'Download ${versionLabels[selectedVersion]} for offline use. This will fetch many chapters and may take time and data.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'No',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Download'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        unawaited(_startDownload(selectedVersion));
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  );
                },
              ),
            ],
          ),
        ),

        // search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search verses (press enter to search)',
            ),
            onSubmitted: (q) => _search(q),
            onChanged: (q) {
              if (q.isEmpty) {
                searchResults = [];
                setState(() {});
              }
            },
          ),
        ),

        const SizedBox(height: 6),

        // content area: either search results or chapter
        Expanded(
          child: _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildChapterView(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return const Center(child: Text('No results (or press Enter to search)'));
    }
    return ListView.separated(
      itemCount: searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = searchResults[i];
        final version = r['version'] ?? selectedVersion;
        final book = r['book'] ?? '';
        final chapter = r['chapter'] ?? 0;
        final verse = r['verse'] ?? 0;
        final text = r['text'] ?? '';
        final key = _keyFor(version, book, chapter as int, verse as int);
        final isBookmarked = _bookmarks.contains(key);
        final isHighlighted = _highlights.contains(key);

        return Column(
          // Use Column to place actions below text
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('$book $chapter:$verse'),
              subtitle: Text(text.toString()),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              tileColor: isHighlighted ? Colors.yellow[100] : null,
              onTap: () {
                // Optionally navigate to this verse in the main view
                selectedVersion = version;
                selectedBook = book;
                selectedChapter = chapter;
                _loadChapter(version, book, chapter).then((_) {
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('Navigated to verse')),
                  // );
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                bottom: 8.0,
              ), // Align with text
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Align actions to the right
                children: [
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.blue.shade700),
                    onPressed: () => _shareVerse(
                      book,
                      chapter as int,
                      verse as int,
                      text.toString(),
                      version.toString(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? Colors.orange.shade700
                          : Colors.blue.shade400,
                    ),
                    onPressed: () => _toggleBookmark(
                      version.toString(),
                      book.toString(),
                      chapter as int,
                      verse as int,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isHighlighted
                          ? Icons.highlight
                          : Icons.highlight_outlined,
                      color: isHighlighted
                          ? Colors.orange.shade700
                          : Colors.blue.shade400,
                    ),
                    onPressed: () => _toggleHighlight(
                      version.toString(),
                      book.toString(),
                      chapter as int,
                      verse as int,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChapterView() {
    return FutureBuilder<bool>(
      future: _isVersionDownloaded(selectedVersion),
      builder: (context, snap) {
        final downloaded = snap.data ?? false;
        if (!downloaded) {
          return Center(
            child: Text(
              'Version ${versionLabels[selectedVersion]} not downloaded. Tap Download above.',
            ),
          );
        }

        // We already have a mechanism to load chapters via dropdowns and initState.
        // The previous unawaited(_loadChapter(...)) here caused the issue.
        // Now, we display the current state of `verses`.
        if (_loadingChapter || verses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          itemCount: verses.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final v = verses[i];
            final verseNum = v['verse'] ?? 0;
            final text = v['text'] ?? '';
            final key = _keyFor(
              selectedVersion,
              selectedBook,
              selectedChapter,
              verseNum as int,
            );
            final isBookmarked = _bookmarks.contains(key);
            final isHighlighted = _highlights.contains(key);

            return Column(
              // Use Column to stack verse and actions
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: isHighlighted ? Colors.yellow[100] : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // verse number
                      SizedBox(
                        width: 40,
                        child: Text(
                          verseNum.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // verse text
                      Expanded(child: Text(text.toString())),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    bottom: 8.0,
                  ), // Adjust padding as needed
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // Align actions to the right
                    children: [
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.blue.shade700),
                        onPressed: () => _shareVerse(
                          selectedBook,
                          selectedChapter,
                          verseNum as int,
                          text.toString(),
                          selectedVersion,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked
                              ? Colors.orange.shade700
                              : Colors.blue.shade400,
                        ),
                        onPressed: () => _toggleBookmark(
                          selectedVersion,
                          selectedBook,
                          selectedChapter,
                          verseNum as int,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isHighlighted
                              ? Icons.highlight
                              : Icons.highlight_outlined,
                          color: isHighlighted
                              ? Colors.orange.shade700
                              : Colors.blue.shade400,
                        ),
                        onPressed: () => _toggleHighlight(
                          selectedVersion,
                          selectedBook,
                          selectedChapter,
                          verseNum as int,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // bookmarks screen
  void _openBookmarks() async {
    final rows = await _dbService.getAllBookmarks();
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        if (rows.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No bookmarks')),
          );
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final r = rows[i];
            final key = r['key'].toString();
            final parts = key.split('|');
            final version = parts[0];
            final book = parts[1];
            final chapter = int.tryParse(parts[2]) ?? 0;
            final verse = int.tryParse(parts[3]) ?? 0;
            return ListTile(
              title: Text('$book $chapter:$verse (${version.toUpperCase()})'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  selectedVersion = version;
                  selectedBook = book;
                  selectedChapter = chapter;
                  // We need to trigger a rebuild of the main BiblePage
                  // after updating selected values and loading the chapter.
                  // Navigator.pop(ctx) will cause a rebuild of the underlying widget.
                  _loadChapter(version, book, chapter).then((_) {
                    Navigator.pop(ctx);
                    // Force a full refresh of the main UI to reflect changes
                    setState(() {});
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  // daily verse
  void _showDailyVerse() async {
    if (await _isVersionDownloaded(selectedVersion) == false) {
      _snack('Version ${versionLabels[selectedVersion]} not downloaded.');
      return;
    }
    final v = await _dailyVerse(selectedVersion);
    if (v == null) {
      _snack('No verse found for ${versionLabels[selectedVersion]}.');
      return;
    }
    final book = v['book'] ?? selectedBook;
    final chapter = v['chapter'] ?? 0;
    final verse = v['verse'] ?? 0;
    final text = v['text'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Daily Verse — $book $chapter:$verse'),
        content: SingleChildScrollView(child: Text(text.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Share.share('$book $chapter:$verse\n\n${text.toString()}');
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

// a helper so we can call a future without awaiting in some places
void unawaited(Future<void> f) {}
