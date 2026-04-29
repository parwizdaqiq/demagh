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
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
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
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Name',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Update your profile information',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: firstController,
                  decoration: InputDecoration(
                    labelText: 'First name',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastController,
                  decoration: InputDecoration(
                    labelText: 'Last name',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
        content: const Text('This action cannot be undone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  Widget _tile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: danger ? Colors.red : Colors.black,
          ),
        ),
        subtitle: value.isEmpty ? null : Text(value),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(children: children),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F4F7),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            child: Column(
              children: [
                _section('Account'),
                _group([
                  _tile(
                    title: 'First Name',
                    value: first,
                    icon: Icons.person,
                    color: const Color(0xFF7C3AED),
                  ),
                  _tile(
                    title: 'Last Name',
                    value: last,
                    icon: Icons.badge,
                    color: const Color(0xFF06B6D4),
                  ),
                  _tile(
                    title: 'Email',
                    value: email,
                    icon: Icons.email,
                    color: const Color(0xFF22C55E),
                  ),
                ]),
                _section('Settings'),
                _group([
                  _tile(
                    title: 'Change Name',
                    value: 'Update your name',
                    icon: Icons.edit,
                    color: Colors.black,
                    onTap: () => _editName(first: first, last: last),
                  ),
                  _tile(
                    title: 'Logout',
                    value: '',
                    icon: Icons.logout,
                    color: Colors.orange,
                    onTap: () => _logout(context),
                  ),
                ]),
                _section('Danger'),
                _group([
                  _tile(
                    title: 'Delete Account',
                    value: '',
                    icon: Icons.delete,
                    color: Colors.red,
                    danger: true,
                    onTap: () => _deleteAccount(context),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}