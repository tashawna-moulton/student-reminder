import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/core/app_theme.dart';
import 'package:students_reminder/src/core/bootstrap.dart';
import 'package:students_reminder/src/shared/routes.dart';
import 'package:students_reminder/src/features/splash/splash_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const ProviderScope(child: StudentsReminderApp()));
}

class StudentsReminderApp extends StatelessWidget {
  const StudentsReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Students Reminder',
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: SplashGate(),
    );
  }
}
