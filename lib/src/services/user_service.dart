import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  //Return Filtered list of students >> web | mobile
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserByCourseGroup(
    String course,
  ) {
    //  course:  "web"  ||  "mobile"
    debugPrint('***>> doc value: ${_db.collection('users').snapshots()}');
    return _db
        .collection('users')
        .where('courseGroup', isEqualTo: course)
        .orderBy('lastName')
        .snapshots();
  }

  //Update a User's info
  Future<void> updateMyProfile(
    String uid, {
    String? gender,
    String? phone,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (gender != null) data['gender'] = gender;
    if (phone != null) data['phone'] = phone;
    if (bio != null) data['bio'] = bio;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  Future<String?> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    //Ensure that permissions are handled in the UI before calling this function
    final ref = _storage.ref().child(
      'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({'photoUrl': url});
    return url;
  }
  // Add this method to your UserService class

Future<void> uploadCoverPhoto({required String uid, required File file}) async {
  try {
    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance
        .ref()
        .child('covers')
        .child('$uid.jpg');
    
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();
    
    // Update user document with cover URL
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'coverUrl': downloadUrl});
        
  } catch (e) {
    throw Exception('Failed to upload cover photo: $e');
  }
}
}
