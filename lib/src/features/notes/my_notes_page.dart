import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/features/notes/dialogs/note_editor_dialog.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/note_service.dart';

class MyNotesPage extends StatelessWidget {
  const MyNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('My Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => NoteEditorDialog(uid: uid),
          );
        },
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: NotesService.instance.watchMyNotes(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No notes to show. Click the + button to add a note.',
              ),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => Divider(height: 2),
            itemBuilder: (context, i) {
              final data = docs[i];
              final visible = data['visibility'] ?? 'private';
              final title = (data['title'] ?? '').toString();
              final body = (data['body'] ?? '').toString();
              return ListTile(
                title: Text(title),
                subtitle: Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Chip(label: Text(visible)),
                onTap: () {},
                trailing: IconButton(
                  onPressed: () async {
                    await NotesService.instance.deleteNote(uid, data['id']);
                  },
                  icon: Icon(Icons.delete_outlined),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
