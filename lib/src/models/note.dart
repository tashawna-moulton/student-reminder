class Note {
  final String id;
  final String title;
  final String body;
  final String visibility; // 'public' | 'private'
  final DateTime? dueDate;
  final DateTime? audDt;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.visibility,
    this.dueDate,
    this.audDt,
  });

  // From Firebase
  //    doc.id >> the document ID (e.g. cx234)
  //    doc.data() >> the map coming from Firestore with the fields (title, body, visibility etc)
  //    Note.fromMap(doc.id, doc.data());
  factory Note.fromMap(String id, Map<String, dynamic> data) {
    return Note(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      visibility: data['visibility'] ?? '',
      dueDate: (data['dueDate']?.toDate()) as DateTime?,
      audDt: (data['audDt']?.toDate()) as DateTime?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'visibility': visibility,
    'dueDate': dueDate,
    'audDt': audDt,
  };
}
