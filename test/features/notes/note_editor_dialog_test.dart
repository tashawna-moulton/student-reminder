import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:students_reminder/src/features/notes/data/note_repository.dart';
import 'package:students_reminder/src/features/notes/dialogs/note_editor_dialog.dart';
import 'package:students_reminder/src/models/note.dart';

class _FakeNoteRepo implements NoteRepository {
  String? createdTitle;
  String? createdBody;
  String? createdVisibility;
  DateTime? createdDue;
  String? lastDeletedId;
  String? lastUpdatedId;

  @override
  Future<String> createNote(String uid,
      {required String title,
      required String body,
      required String visibility,
      DateTime? dueDate}) async {
    createdTitle = title;
    createdBody = body;
    createdVisibility = visibility;
    createdDue = dueDate;
    return 'new-id';
  }

  @override
  Future<void> deleteNote(String uid, String noteId) async {
    lastDeletedId = noteId;
  }

  @override
  Future<void> updateNote(String uid, String noteId,
      {String? title, String? body, String? visibility, DateTime? dueDate}) async {
    lastUpdatedId = noteId;
    createdTitle = title;
    createdBody = body;
    createdVisibility = visibility;
    createdDue = dueDate;
  }

  @override
  Stream<List<Note>> watchPublicNotes(String uid) => const Stream.empty();

  @override
  Stream<List<Note>> watchUserNotes(String uid) => const Stream.empty();
}

void main() {
  testWidgets('NoteEditorDialog validates and creates note', (tester) async {
    final fake = _FakeNoteRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      ),
    );

    // Open the dialog
    showDialog(
      context: tester.element(find.byType(SizedBox)),
      builder: (_) => const NoteEditorDialog(uid: 'u1'),
    );
    await tester.pumpAndSettle();

    // Initially invalid, try save
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Body is required'), findsOneWidget);

    // Fill in fields and save
    await tester.enterText(find.byType(TextFormField).at(0), 'Title');
    await tester.enterText(find.byType(TextFormField).at(1), 'Body');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.createdTitle, 'Title');
    expect(fake.createdBody, 'Body');
    expect(fake.createdVisibility, isNotNull);
  });
}

