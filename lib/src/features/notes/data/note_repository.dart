import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/models/note.dart';
import 'package:students_reminder/src/services/note_service.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchUserNotes(String uid);
  Stream<List<Note>> watchPublicNotes(String uid);
  Future<String> createNote(
    String uid, {
    required String title,
    required String body,
    required String visibility,
    DateTime? dueDate,
  });
  Future<void> updateNote(
    String uid,
    String noteId, {
    String? title,
    String? body,
    String? visibility,
    DateTime? dueDate,
  });
  Future<void> deleteNote(String uid, String noteId);
}

class FirebaseNoteRepository implements NoteRepository {
  final NotesService _service;

  FirebaseNoteRepository(this._service);

  @override
  Stream<List<Note>> watchUserNotes(String uid) {
    return _service.watchMyNotes(uid).map((QuerySnapshot<Map<String, dynamic>> snap) {
      return snap.docs
          .map((d) => Note.fromMap(d.id, d.data()))
          .toList(growable: false);
    });
  }

  @override
  Stream<List<Note>> watchPublicNotes(String uid) {
    return _service.watchPublicNotes(uid).map((snap) => snap.docs
        .map((d) => Note.fromMap(d.id, d.data()))
        .toList(growable: false));
  }

  @override
  Future<String> createNote(
    String uid, {
    required String title,
    required String body,
    required String visibility,
    DateTime? dueDate,
  }) {
    return _service.createNote(
      uid,
      title: title,
      body: body,
      visibility: visibility,
      dueDate: dueDate,
    );
  }

  @override
  Future<void> deleteNote(String uid, String noteId) {
    return _service.deleteNote(uid, noteId);
  }

  @override
  Future<void> updateNote(
    String uid,
    String noteId, {
    String? title,
    String? body,
    String? visibility,
    DateTime? dueDate,
  }) {
    return _service.updateNote(
      uid,
      noteId,
      title: title,
      body: body,
      visibility: visibility,
      dueDate: dueDate,
    );
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return FirebaseNoteRepository(NotesService.instance);
});

final notesStreamProvider = StreamProvider.family<List<Note>, String>((ref, uid) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchUserNotes(uid);
});

