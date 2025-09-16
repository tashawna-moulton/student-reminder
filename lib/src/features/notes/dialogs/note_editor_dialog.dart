import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/features/notes/data/note_repository.dart';
import 'package:students_reminder/src/models/note.dart';

class NoteEditorDialog extends ConsumerStatefulWidget {
  final String uid;
  final Note? note;

  const NoteEditorDialog({
    super.key,
    required this.uid,
    this.note,
  });

  @override
  ConsumerState<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<NoteEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _body;

  String _visibility = 'private';
  DateTime? _due;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _body = TextEditingController(text: widget.note?.body ?? '');
    _visibility = widget.note?.visibility ?? 'private';
    _due = widget.note?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(noteRepositoryProvider);
    try {
      if (widget.note == null) {
        await repo.createNote(
          widget.uid,
          title: _title.text.trim(),
          body: _body.text.trim(),
          visibility: _visibility,
          dueDate: _due,
        );
      } else {
        await repo.updateNote(
          widget.uid,
          widget.note!.id,
          title: _title.text.trim(),
          body: _body.text.trim(),
          visibility: _visibility,
          dueDate: _due,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                decoration: const InputDecoration(labelText: 'Body'),
                minLines: 2,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Body is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Visibility'),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _visibility,
                    items: const [
                      DropdownMenuItem(
                          value: 'private', child: Text('Private')),
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                    ],
                    onChanged: (v) => setState(() => _visibility = v ?? 'private'),
                  ),
                  const SizedBox(width: 16),
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
                          : _due!.toString().split(' ').first,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
