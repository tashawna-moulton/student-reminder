import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/features/notes/dialogs/note_dialog_v2.dart';
import 'package:students_reminder/src/features/notes/dialogs/note_editor_bottom_sheet.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/note_service.dart';

class MyNotesPage extends StatelessWidget {
  const MyNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
              
              NoteEditorDialog(uid: uid)
              ,));
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // --- New Bottom Sheet Editor ---
          final note = await showNoteEditorBottomSheet(context);
          if (note != null) {}
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: NotesService.instance.watchMyNotes(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notes to show. Click the + button to add a note.',
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 2),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final noteId = doc.id;
              final visible = doc['visibility'] ?? 'private';
              final title = (doc['title'] ?? '').toString();
              final body = (doc['body'] ?? '').toString();

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Chip(label: Text(visible)),
                onTap: () async {
                  // --- New Bottom Sheet Editor for editing ---
                  final note = await showNoteEditorBottomSheet(
                    context,
                    initial: Note(id: noteId, title: title, body: body),
                  );
                  if (note != null) {}
                },
                trailing: IconButton(
                  onPressed: () async {
                    await NotesService.instance.deleteNote(uid, noteId);
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
