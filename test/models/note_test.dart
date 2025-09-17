import 'package:flutter_test/flutter_test.dart';
import 'package:students_reminder/src/models/note.dart';

void main() {
  test('Note.toMap outputs expected keys', () {
    final note = Note(
      id: 'n1',
      title: 'T',
      body: 'B',
      visibility: 'private',
      dueDate: DateTime(2024, 1, 1),
      audDt: DateTime(2024, 1, 2),
    );

    final map = note.toMap();
    expect(map['title'], 'T');
    expect(map['body'], 'B');
    expect(map['visibility'], 'private');
    expect(map['dueDate'], isA<DateTime?>());
    expect(map['aud_dt'], isA<DateTime?>());
  });

  test('Note.fromMap maps fields with defaults', () {
    final data = {
      'title': 'Hello',
      'body': 'World',
      'visibility': 'public',
    };
    final note = Note.fromMap('123', data);
    expect(note.id, '123');
    expect(note.title, 'Hello');
    expect(note.body, 'World');
    expect(note.visibility, 'public');
    expect(note.dueDate, isNull);
    expect(note.audDt, isNull);
  });
}
