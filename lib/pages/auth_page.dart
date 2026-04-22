import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session != null) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}