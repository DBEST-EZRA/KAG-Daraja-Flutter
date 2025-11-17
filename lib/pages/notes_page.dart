// notes_page.dart (Your main file, replacing the old content)
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'note_model.dart';
import 'note_editor_page.dart';
import 'note_viewer_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
    _searchController.addListener(_searchNotes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchNotes);
    _searchController.dispose();
    super.dispose();
  }

  // Database Refresh Method
  Future _refreshNotes() async {
    setState(() => _isLoading = true);
    _notes = await NoteDatabase.instance.readAllNotes();
    _searchNotes(); // Re-apply search filter
    setState(() => _isLoading = false);
  }

  void _searchNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes
            .where(
              (note) =>
                  note.title.toLowerCase().contains(query) ||
                  note.content.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  // Navigation Handlers
  void _navigateToAddNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorPage()),
    );
    if (result == true) {
      _refreshNotes();
    }
  }

  void _navigateToViewNote(Note note) async {
    // The NoteViewerPage handles the logic for edit/delete, then pops back
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteViewerPage(
          note: note,
          onDelete: () async {
            await NoteDatabase.instance.delete(note.id!);
            _refreshNotes();
          },
          onEdit: () async {
            Navigator.pop(context); // Close viewer page
            final editResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorPage(note: note),
              ),
            );
            if (editResult == true) {
              _refreshNotes();
            }
          },
        ),
      ),
    );
    if (result == true) {
      _refreshNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Notes',
          style: TextStyle(
            color: Colors.white, // <--- Add this line
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          CircleAvatar(
            radius: 20, // Adjust size as needed
            backgroundColor: Colors.orange, // The orange circle background
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white, // The white icon color
              ),
              onPressed: _navigateToAddNote,
              tooltip: 'Add New Note',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search notes by title or content...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'No notes saved yet. Tap + to add one.'
                          : 'No matching notes found.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredNotes.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      final preview = note.content.length > 50
                          ? '${note.content.substring(0, 50).trim()}...'
                          : note.content;
                      return ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () {
                            Share.share('${note.title}\n\n${note.content}');
                          },
                        ),
                        onTap: () => _navigateToViewNote(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
