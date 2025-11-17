// note_editor_page.dart
import 'package:flutter/material.dart';
import 'note_model.dart';
import 'note_liner.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim().isEmpty
          ? 'Untitled Note'
          : _titleController.text.trim();
      final content = _contentController.text.trim();

      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note content cannot be empty.')),
        );
        return;
      }

      if (widget.note == null) {
        // Create new note
        await NoteDatabase.instance.create(
          Note(title: title, content: content, creationTime: DateTime.now()),
        );
      } else {
        // Update existing note
        await NoteDatabase.instance.update(
          Note(
            id: widget.note!.id,
            title: title,
            content: content,
            creationTime: widget.note!.creationTime,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Pop and signal successful save
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: NotebookLiner(
                  child: TextFormField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Write your note here...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 8, bottom: 8),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                    ), // Adjust to line height
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Content cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
