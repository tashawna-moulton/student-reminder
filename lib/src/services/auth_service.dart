import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/services/session_manager.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanged() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Register CODE
  Future<UserCredential> register({
    required String firstName,
    required String lastName,
    required String courseGroup, // 'web' | 'mobile'
    required String email,
    required String phone,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'courseGroup': courseGroup,
      'email': email,
      'phone': phone,
      'gender': null,
      'bio': null,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'student', // 👈 Default role when registering
    });
    await SessionManager.onLoginSuccess();
    return cred;
  }

  // Login CODE
  Future<UserCredential> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await SessionManager.onLoginSuccess();
    return cred;
  }

  // Logout CODE
  Future<void> logout() async {
    await _auth.signOut();
    await SessionManager.clear();
  }

  // Password Reset CODE
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // Get User Role CODE
  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data()?['role'] as String?;
  }

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return false;
    final role = snap.data()?['role'] as String?;
    return role == 'admin';
  }
}