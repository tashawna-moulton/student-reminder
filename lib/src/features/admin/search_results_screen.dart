import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/widgets/student_pillrow.dart' as student;

class SearchResultsScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> results;

  const SearchResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Results"),
        backgroundColor: Colors.black,
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                "No students found",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final data = results[i].data() as Map<String, dynamic>;
                final first = (data['firstName'] ?? '').toString().trim();
                final last = (data['lastName'] ?? '').toString().trim();
                final name = (first.isEmpty && last.isEmpty)
                    ? "Student"
                    : "$first $last";
                final photoUrl = data['photoUrl'];
                final status = data['status'] ?? 'unknown';

                return student.StudentRow(
                  name: name,
                  status: status,
                  photoUrl: photoUrl,
                  reason: data['lateReason'],
                  onPresent: () async =>
                      await results[i].reference.update({'status': 'present'}),
                  onAbsent: () async =>
                      await results[i].reference.update({'status': 'absent'}),
                  onEditReason: () async =>
                      await results[i].reference.update({'status': 'late'}),
                );
              },
            ),
    );
  }
}