import 'package:flutter/material.dart';
import 'package:students_reminder/src/features/auth/login_page.dart';
import 'package:students_reminder/src/features/auth/register_page.dart';
import 'package:students_reminder/src/features/profile/student_profile_page.dart';
import 'package:students_reminder/src/features/splash/splash_gate.dart';
import 'package:students_reminder/src/shared/main_layout.dart';
import 'package:students_reminder/src/features/intro/intro_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const intro = '/intro';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';

  static Route<dynamic> onGenerateRoute(RouteSettings setting) {
    final url = Uri.parse(setting.name ?? '');

    if (url.pathSegments.isNotEmpty && url.pathSegments[0] == 'student') {
      final uid = url.pathSegments.length > 1 ? url.pathSegments[1] : '';
      return MaterialPageRoute(builder: (_) => StudentProfilePage(uid: uid));
    }

    switch (setting.name) {
      case splash:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashGate(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        );

      case intro:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const IntroScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        );

      case login:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 400),
        );

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case main:
        return MaterialPageRoute(builder: (_) => const MainLayoutPage());

      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
