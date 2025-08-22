import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:students_reminder/src/features/auth/login_page.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/shared/main_layout.dart';

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanged(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // if (snap.data == null) {
        //   return LoginPage();
        // }
        final user = snap.data;
        if (user == null) return LoginPage();
        debugPrint('*** currentUserInfo at startup: ${AuthService.instance.currentUser}');
        return MainLayoutPage();
        // return LoginPage();
      },
    );
  }
}
