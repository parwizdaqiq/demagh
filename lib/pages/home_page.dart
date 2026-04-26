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

  // Task settings
  String _priority = 'normal'; // normal | priority
  String _repeatType = 'none'; // none | daily | specific
  DateTime? _specificDate;

  // Category filter
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Personal',
    'Assignments',
    'Meet',
    'Job',
  ];

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

    if (user == null) return [];

    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addTask(String title, String time) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;
    if (title.trim().isEmpty) return;

    await supabase.from('tasks').insert({
      'title': title.trim(),
      'user_id': user.id,
      'time': time,
      'is_completed': false,
      'priority': _priority,
      'repeat_type': _repeatType,
      'specific_date': _specificDate?.toIso8601String(),
    });
  }

  Future<void> updateTask(String id, String title, String time) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;
    if (title.trim().isEmpty) return;

    await supabase
        .from('tasks')
        .update({
          'title': title.trim(),
          'time': time,
          'priority': _priority,
          'repeat_type': _repeatType,
          'specific_date': _specificDate?.toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> updateTaskCompletion(String id, bool value) async {
    await supabase.from('tasks').update({'is_completed': value}).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
  }

  String _formatSelectedTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _timeFromString(String? time) {
    if (time == null || !time.contains(':')) {
      return TimeOfDay.now();
    }

    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? TimeOfDay.now().hour;
    final minute = int.tryParse(parts[1]) ?? TimeOfDay.now().minute;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTaskOptions(StateSetter setModalState) {
    return Column(
      children: [
        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Task Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Only priority button
        InkWell(
          onTap: () {
            setModalState(() {
              _priority = _priority == 'priority' ? 'normal' : 'priority';
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _priority == 'priority'
                  ? const Color(0xFFFFE4E6)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _priority == 'priority'
                    ? const Color(0xFFFB7185)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _priority == 'priority'
                      ? Icons.flag_rounded
                      : Icons.flag_outlined,
                  color: _priority == 'priority'
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF111827),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _priority == 'priority'
                        ? 'Priority task selected'
                        : 'Mark as priority',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _priority == 'priority'
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Repeat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: _repeatType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'none',
              child: Text('No repeat'),
            ),
            DropdownMenuItem(
              value: 'daily',
              child: Text('Daily'),
            ),
            DropdownMenuItem(
              value: 'specific',
              child: Text('Specific date'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setModalState(() {
              _repeatType = value;

              if (_repeatType != 'specific') {
                _specificDate = null;
              }
            });
          },
        ),

        if (_repeatType == 'specific') ...[
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _specificDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setModalState(() {
                  _specificDate = picked;
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
                  const Icon(Icons.calendar_today_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _specificDate == null
                          ? 'Choose specific date'
                          : 'Date: ${_formatDate(_specificDate!)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddTaskSheet() {
    _taskController.clear();
    _selectedTime = null;

    _priority = 'normal';
    _repeatType = 'none';
    _specificDate = null;

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
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
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
                      _buildTaskOptions(setModalState),
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

                            if (_repeatType == 'specific' &&
                                _specificDate == null) {
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
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTaskSheet(Map<String, dynamic> task) {
    final editController = TextEditingController(text: task['title'] ?? '');
    TimeOfDay? editTime = _timeFromString(task['time']);

    final savedPriority = task['priority'] ?? 'normal';
    _priority = savedPriority == 'high' ? 'priority' : savedPriority;

    _repeatType = task['repeat_type'] ?? 'none';
    _specificDate = task['specific_date'] != null
        ? DateTime.tryParse(task['specific_date'])
        : null;

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
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
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
                          'Edit Task',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: editController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Update task name',
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
                            initialTime: editTime ?? TimeOfDay.now(),
                          );

                          if (picked != null) {
                            setModalState(() {
                              editTime = picked;
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
                                  editTime == null
                                      ? 'Choose task time'
                                      : 'Time: ${_formatSelectedTime(editTime!)}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                      _buildTaskOptions(setModalState),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (editController.text.trim().isEmpty ||
                                editTime == null) {
                              return;
                            }

                            if (_repeatType == 'specific' &&
                                _specificDate == null) {
                              return;
                            }

                            await updateTask(
                              task['id'],
                              editController.text,
                              _formatSelectedTime(editTime!),
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
                            'Save Changes',
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
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
          const SizedBox(height: 8),
          Text(
            'Qasm Wakhla che pa Yad de wa',
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

  Widget _buildBadge({
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6, right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['is_completed'] ?? false;

    final rawPriority = task['priority'] ?? 'normal';
    final priority = rawPriority == 'high' ? 'priority' : rawPriority;

    final repeatType = task['repeat_type'] ?? 'none';
    final specificDate = task['specific_date'];

    final isPriority = priority == 'priority';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPriority ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isPriority ? const Color(0xFFFFCDD2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: (value) async {
              if (value == null) return;

              await updateTaskCompletion(task['id'], value);

              if (!mounted) return;
              setState(() {});
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? Colors.grey
                        : const Color(0xFF111827),
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
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
                        task['time'] ?? 'No time',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    if (isPriority)
                      _buildBadge(
                        text: 'PRIORITY TASK',
                        textColor: const Color(0xFFBE123C),
                        backgroundColor: const Color(0xFFFFE4E6),
                      ),
                    if (repeatType == 'daily')
                      _buildBadge(
                        text: 'DAILY',
                        textColor: Colors.blue.shade700,
                        backgroundColor: Colors.blue.shade50,
                      ),
                    if (repeatType == 'specific')
                      _buildBadge(
                        text: specificDate == null
                            ? 'SPECIFIC DATE'
                            : 'DATE: $specificDate',
                        textColor: Colors.purple.shade700,
                        backgroundColor: Colors.purple.shade50,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditTaskSheet(task),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await deleteTask(task['id']);
                  if (!mounted) return;
                  setState(() {});
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildFilterChips() {
  return Row(
    children: [
      ChoiceChip(
        label: const Text('All'),
        selected: _selectedCategory == 'All',
        selectedColor: const Color(0xFF111827),
        labelStyle: TextStyle(
          color: _selectedCategory == 'All' ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategory = 'All';
          });
        },
      ),
      const SizedBox(width: 10),
      ChoiceChip(
        label: const Text('Priority'),
        selected: _selectedCategory == 'Priority',
        selectedColor: const Color(0xFFFFE4E6),
        labelStyle: TextStyle(
          color: _selectedCategory == 'Priority'
              ? const Color(0xFFE11D48)
              : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategory = 'Priority';
          });
        },
      ),
    ],
  );
}

  @override
  void dispose() {
    _taskController.dispose();
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
            _buildHeader(),
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
              const SizedBox(height: 12),
              _buildFilterChips(),
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
                  final allTasks = snapshot.data ?? [];

              final tasks = _selectedCategory == 'Priority'
                  ? allTasks
                      .where((task) =>
                          task['priority'] == 'priority' || task['priority'] == 'high')
                      .toList()
                  : allTasks;

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
                          Text(
                            _selectedCategory == 'All'
                                ? 'No tasks yet'
                                : 'No $_selectedCategory tasks yet',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory == 'All'
                                ? 'Tap the + button and add your first task.'
                                : 'Add a task in $_selectedCategory to see it here.',
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
    );
  }
}