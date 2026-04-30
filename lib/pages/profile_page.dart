import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>?> _profileFuture;

  static const primary = Color(0xFF7C3AED);
  static const bg = Color(0xFFF8FAFC);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchProfile();
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = fetchProfile();
    });
  }

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _editName({
    required String first,
    required String last,
  }) async {
    final firstController = TextEditingController(text: first);
    final lastController = TextEditingController(text: last);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Change Name',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _inputField(
                  controller: firstController,
                  label: 'First name',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: lastController,
                  label: 'Last name',
                  icon: Icons.badge_rounded,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({
      'first_name': firstController.text.trim(),
      'last_name': lastController.text.trim(),
    }).eq('id', user.id);

    _refreshProfile();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await supabase.rpc('delete_my_account');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  static Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool dangerStyle = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: dangerStyle ? danger : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topIntro(String first, String last) {
    final name = '$first $last'.trim().isEmpty ? 'User' : '$first $last';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B2EFF),
            Color(0xFF8B2CF5),
            Color(0xFFB832D4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Settings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final first = data['first_name'] ?? '';
          final last = data['last_name'] ?? '';
          final email = data['email'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              children: [
                _topIntro(first, last),

                _sectionTitle('Account'),
                _tile(
                  title: 'First Name',
                  subtitle: first,
                  icon: Icons.person_rounded,
                  color: primary,
                ),
                _tile(
                  title: 'Last Name',
                  subtitle: last,
                  icon: Icons.badge_rounded,
                  color: const Color(0xFF06B6D4),
                ),
                _tile(
                  title: 'Email',
                  subtitle: email,
                  icon: Icons.email_rounded,
                  color: success,
                ),

                _sectionTitle('Settings'),
                _tile(
                  title: 'Change Name',
                  subtitle: 'Update your display name',
                  icon: Icons.edit_rounded,
                  color: primary,
                  onTap: () => _editName(first: first, last: last),
                ),
                _tile(
                  title: 'Logout',
                  subtitle: 'Sign out from this device',
                  icon: Icons.logout_rounded,
                  color: const Color(0xFFF97316),
                  onTap: () => _logout(context),
                ),

                _sectionTitle('Danger Zone'),
                _tile(
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  icon: Icons.delete_outline_rounded,
                  color: danger,
                  dangerStyle: true,
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}