import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth_page.dart';
import 'services/notification_service.dart'; // ✅ ADD THIS

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Supabase init
  await Supabase.initialize(
    url: 'https://hjhbewzrmbwrscklzdzc.supabase.co',
    anonKey: 'sb_publishable_dyggsC_SeSaDYwfMPF4iNA_ZtwOoCfd',
  );

  // ✅ Notifications init
  await NotificationService.init();

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dimagh',
      theme: ThemeData(
        primaryColor: const Color(0xFF7C3AED),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const AuthPage(),
    );
  }
}