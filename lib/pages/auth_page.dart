import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';
import 'main_navigation_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session != null) {
      return const MainNavigationPage();
    } else {
      return const LoginPage();
    }
  }
}