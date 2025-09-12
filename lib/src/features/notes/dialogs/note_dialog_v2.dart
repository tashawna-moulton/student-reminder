import 'package:flutter/material.dart';
import 'package:students_reminder/src/services/note_service.dart';

class NoteEditorDialog extends StatefulWidget {
  final String uid;
  final String? noteId;
  final Map<String, dynamic>? existing;

  const NoteEditorDialog({
    super.key,
    required this.uid,
    this.noteId,
    this.existing,
  });

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _tags; // New controller for tags

  String _visibility = 'private';
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?['title'] ?? '');
    _body = TextEditingController(text: widget.existing?['body'] ?? '');
    _visibility = widget.existing?['visibility'] ?? 'private';
    final dueTS = widget.existing?['dueDate'];
    if (dueTS != null) {
      _due = dueTS.toDate();
    }

    // Initialize tags controller from existing data
    final existingTags = List<String>.from(widget.existing?['tags'] ?? []);
    _tags = TextEditingController(text: existingTags.join(', '));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: null, // Allow multiple lines for the body
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g., school, math, homework',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Visibility'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _visibility,
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                  ],
                  onChanged: (v) => setState(() => _visibility = v ?? 'private'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.event),
                  onPressed: () async {
                    final now = DateTime.now();
                    final selDate = await showDatePicker(
                      context: context,
                      firstDate: now.subtract(const Duration(days: 365 * 2)),
                      lastDate: now.add(const Duration(days: 365 * 5)),
                      initialDate: _due ?? now,
                    );
                    if (selDate != null) setState(() => _due = selDate);
                  },
                  label: Text(
                    _due == null
                        ? 'Due Date'
                        : _due!.toString().split(' ')[0],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final tagsList = _tags.text
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();

            if (widget.noteId == null) {
              await NotesService.instance.createNote(
                widget.uid,
                title: _title.text.trim(),
                body: _body.text.trim(),
                visibility: _visibility,
                dueDate: _due,
                tags: tagsList, // Pass the new tags list
              );
            } else {
              await NotesService.instance.updateNote(
                widget.uid,
                widget.noteId!,
                title: _title.text.trim(),
                body: _body.text.trim(),
                visibility: _visibility,
                dueDate: _due,
                tags: tagsList, // Pass the new tags list
              );
            }
            if (mounted) Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}