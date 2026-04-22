import 'package:flutter/material.dart';
import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

Future<void> _register() async {
  final firstName = _firstNameController.text.trim();
  final lastName = _lastNameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (firstName.isEmpty ||
      lastName.isEmpty ||
      email.isEmpty ||
      password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // 1️⃣ Create account
    await supabase.auth.signUp(
      email: email,
      password: password,
    );

    // 2️⃣ FORCE LOGIN (important)
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    // 3️⃣ Insert profile (now auth.uid() works)
    await supabase.from('profiles').upsert({
      'id': user.id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful 🎉')),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration failed: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Register',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Create your account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Enter your details to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _firstNameController,
              decoration: _inputDecoration('First name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lastNameController,
              decoration: _inputDecoration('Last name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              decoration: _inputDecoration('Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              decoration: _inputDecoration('Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}