// note_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'note_model.dart';
import 'note_liner.dart';

class NoteViewerPage extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const NoteViewerPage({
    super.key,
    required this.note,
    required this.onDelete,
    required this.onEdit,
  });

  void _shareNote(BuildContext context) {
    Share.share('${note.title}\n\n${note.content}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
            tooltip: 'Edit Note',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareNote(context),
            tooltip: 'Share Note',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Confirmation Dialog before deleting
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Deletion'),
                  content: const Text(
                    'Are you sure you want to delete this note?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close alert
                        Navigator.pop(context); // Close viewer page
                        onDelete(); // Execute deletion
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete Note',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Created: ${DateFormat('MMM dd, yyyy - hh:mm a').format(note.creationTime)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: NotebookLiner(
                  showHorizontalLines: true,
                  child: Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
