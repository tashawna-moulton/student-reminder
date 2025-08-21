import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/firebase_options.dart';

Future<void> initFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
