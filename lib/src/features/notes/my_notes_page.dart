import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/features/notes/data/note_repository.dart';
import 'package:students_reminder/src/features/notes/dialogs/note_editor_dialog.dart';
import 'package:students_reminder/src/models/note.dart';
import 'package:students_reminder/src/services/auth_service.dart';

class MyNotesPage extends ConsumerWidget {
  const MyNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = AuthService.instance.currentUser!.uid;
    final notesAsync = ref.watch(notesStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => NoteEditorDialog(uid: uid),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load notes: $e')),
        data: (List<Note> notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('No notes to show. Click + to add a note.'),
            );
          }
          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (_, __) => const Divider(height: 2),
            itemBuilder: (context, i) {
              final note = notes[i];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(
                  note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Chip(label: Text(note.visibility)),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => NoteEditorDialog(uid: uid, note: note),
                  );
                },
                trailing: IconButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Note'),
                        content: const Text('Are you sure you want to delete this note?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(noteRepositoryProvider).deleteNote(uid, note.id);
                    }
                  },
                  icon: const Icon(Icons.delete_outlined),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
