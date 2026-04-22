import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _taskController = TextEditingController();
  TimeOfDay? _selectedTime;

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final user = supabase.auth.currentUser;

    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addTask(String title, String time) async {
    final user = supabase.auth.currentUser;

    if (title.trim().isEmpty) return;

    await supabase.from('tasks').insert({
      'title': title.trim(),
      'user_id': user!.id,
      'time': time,
    });
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
  }

  String _formatSelectedTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getFirstName(String? email) {
    if (email == null || email.isEmpty) return 'User';
    return email.split('@').first;
  }

  void _showAddTaskSheet() {
    _taskController.clear();
    _selectedTime = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add New Task',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taskController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'What do you need to do?',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (picked != null) {
                          setModalState(() {
                            _selectedTime = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedTime == null
                                    ? 'Choose task time'
                                    : 'Time: ${_formatSelectedTime(_selectedTime!)}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_taskController.text.trim().isEmpty ||
                              _selectedTime == null) {
                            return;
                          }

                          await addTask(
                            _taskController.text,
                            _formatSelectedTime(_selectedTime!),
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Save Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demagh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back, ${_getFirstName(email)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task['time'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await deleteTask(task['id']);
              if (!mounted) return;
              setState(() {});
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Demagh',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF111827)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            _buildHeader(user?.email),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Your Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Synced',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Something went wrong.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 34,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tasks yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button and add your first task.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}