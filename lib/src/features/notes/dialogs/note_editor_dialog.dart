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

  String _visibility = 'private';
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?['title'] ?? '');
    _body = TextEditingController(text: widget.existing?['body'] ?? '');
    _visibility = widget.existing?['visibiity'] ?? 'private';
    final dueTS = widget.existing?['dueDate'];
    if (dueTS != null) {
      _due = dueTS.toDate();
    }
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
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 12),

            TextField(
              controller: _body,
              decoration: InputDecoration(labelText: 'Body'),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text('Visibility'),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _visibility,
                  items: [
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                  ],
                  onChanged: (v) =>
                      setState(() => _visibility = v ?? 'private'),
                ),

                SizedBox(height: 12),
                TextButton.icon(
                  icon: Icon(Icons.event),
                  onPressed: () async {
                    final now = DateTime.now();
                    final selDate = await showDatePicker(
                      context: context,
                      firstDate: now.subtract(Duration(days: 365 * 2)),
                      lastDate: now.add(Duration(days: 365 * 5)),
                      initialDate: _due ?? now,
                    );
                    if (selDate != null) setState(() => _due = selDate);
                  },
                  label: Text(
                    _due == null
                        ? 'Due Date'
                        : _due!.toString().split(' ').first,
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
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (widget.noteId == null) {
              await NotesService.instance.createNote(
                widget.uid,
                title: _title.text.trim(),
                body: _body.text.trim(),
                visibility: _visibility,
                dueDate: _due
              );
            } else{
               await NotesService.instance.updateNote(
                widget.uid,
                widget.noteId!,
                title: _title.text.trim(),
                body: _body.text.trim(),
                visibility: _visibility,
                dueDate: _due
              );
            }
            if(mounted) Navigator.pop(context, true);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
