import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class Note {
  String title;
  String content;

  Note({required this.title, required this.content});
}

class _NotesPageState extends State<NotesPage> {
  final List<Note> _notes = [];
  final TextEditingController _searchController = TextEditingController();
  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _filteredNotes = _notes;
    _searchController.addListener(_searchNotes);
  }

  void _searchNotes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes
          .where(
            (note) =>
                note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  void _addNote() {
    String title = '';
    String content = '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Add New Note',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: Colors.yellow[50],
                      ),
                      child: TextField(
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Write your note here...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                        ),
                        onChanged: (value) => content = value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (title.trim().isEmpty && content.trim().isEmpty)
                            return;
                          setState(() {
                            _notes.add(Note(title: title, content: content));
                            _filteredNotes = _notes;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _viewNote(Note note) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.yellow[50],
                        ),
                        child: Text(
                          note.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          Share.share('${note.title}\n\n${note.content}');
                        },
                        icon: const Icon(Icons.share),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _notes.remove(note);
                            _filteredNotes = _notes;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.blue,
        actions: [IconButton(onPressed: _addNote, icon: const Icon(Icons.add))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredNotes.isEmpty
                ? const Center(child: Text('No notes found'))
                : ListView.builder(
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return ListTile(
                        title: Text(note.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            Share.share('${note.title}\n\n${note.content}');
                          },
                        ),
                        onTap: () => _viewNote(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
