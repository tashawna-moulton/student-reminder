import 'package:flutter/material.dart';
import 'package:students_reminder/src/services/note_service.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/shared/snackbar_helper.dart';

class Note {
  String id;
  String title;
  String body;

  Note({required this.id, required this.title, required this.body});
}

Future<Note?> showNoteEditorBottomSheet(BuildContext context, {Note? initial}) {
  return showModalBottomSheet<Note?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NoteEditorSheet(initial: initial),
  );
}

class _NoteEditorSheet extends StatefulWidget {
  final Note? initial;
  const _NoteEditorSheet({this.initial});

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSaving = false;

  static const int _titleMax = 80;
  static const int _bodyMax = 2000;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _titleController.text = widget.initial!.title;
      _bodyController.text = widget.initial!.body;
    }
    _titleController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onChanged);
    _bodyController.removeListener(_onChanged);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isValid {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    return title.isNotEmpty && title.length <= _titleMax && body.length <= _bodyMax;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uid = AuthService.instance.currentUser!.uid;

      if (widget.initial == null) {
        final newId = await NotesService.instance.createNote(
          uid,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          visibility: 'private',
        );

        SnackbarHelper.showSuccess(context, 'Note created');
        Navigator.of(context).pop(
          Note(id: newId, title: _titleController.text.trim(), body: _bodyController.text.trim()),
        );
      } else {
        await NotesService.instance.updateNote(
          uid,
          widget.initial!.id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );

        SnackbarHelper.showSuccess(context, 'Note updated');
        Navigator.of(context).pop(
          Note(id: widget.initial!.id, title: _titleController.text.trim(), body: _bodyController.text.trim()),
        );
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to save note: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Drag indicator
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            maxLength: _titleMax,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Enter a title',
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Title cannot be empty';
                              if (value.length > _titleMax) return 'Title too long';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _bodyController,
                            keyboardType: TextInputType.multiline,
                            minLines: 6,
                            maxLines: null,
                            maxLength: _bodyMax,
                            decoration: const InputDecoration(
                              labelText: 'Body',
                              hintText: 'Write your note',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) {
                              final value = v ?? '';
                              if (value.length > _bodyMax) return 'Body too long';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Save / Cancel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: (!_isValid || _isSaving) ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
