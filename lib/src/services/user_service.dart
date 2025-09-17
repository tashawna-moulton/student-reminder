import 'dart:typed_data';
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
      await _db
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    }
  }

  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String? fileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _resolveExtension(fileName);
    final ref = _storage.ref().child('avatars/$uid/$timestamp$extension');

    // Upload the raw bytes so this works on every platform (web/mobile/desktop)
    await ref.putData(bytes, SettableMetadata(contentType: _contentType(extension)));

    final url = await ref.getDownloadURL();
    await _db
        .collection('users')
        .doc(uid)
        .set({'photoUrl': url}, SetOptions(merge: true));
    return url;
  }

  String _resolveExtension(String? fileName) {
    if (fileName != null) {
      final dotIndex = fileName.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < fileName.length - 1) {
        return fileName.substring(dotIndex).toLowerCase();
      }
    }
    return '.jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
