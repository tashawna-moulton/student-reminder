import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/services/user_service.dart';

class StudentProfilePage extends StatelessWidget {
  final String uid;
  const StudentProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: UserService.instance.getUser(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.data();
          if (data == null) return Center(child: Text('No data found'));
          final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
              .trim();
          final group = (data['courseGroup'] ?? '').toString() == 'mobile'
              ? 'Mobile App Development'
              : 'Web App Development';
          final bio = (data['bio'] ?? '') as String? ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(group),
                leading: data['photoUrl'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(data['photoUrl']),
                      )
                    : CircleAvatar(child: Icon(Icons.person)),
              ),
              if (bio.isNotEmpty)
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(bio),
                ),
              // TODO: Add Notes section
            ],
          );
        },
      ),
    );
  }
}
