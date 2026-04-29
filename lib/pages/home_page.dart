import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';
import 'add_task_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
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
  Future<void> updateTaskCompletion(String id, bool value) async {
    await supabase.from('tasks').update({'is_completed': value}).eq('id', id);
  }
  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
  }
  Future<void> updateTask({
    required String id,
    required String title,
    required String description,
    required String priority,
  }) async {
    await supabase.from('tasks').update({
      'title': title,
      'description': description,
      'priority': priority,
    }).eq('id', id);
  }
  bool _isPriority(Map<String, dynamic> task) {
    return task['priority'] == 'priority' || task['priority'] == 'high';
  }
  String _taskTime(Map<String, dynamic> task) {
    final time = task['time'];
    if (time == null || time.toString().isEmpty) return 'No time';
    return time.toString();
  }
  Future<void> _showEditTaskSheet(Map<String, dynamic> task) async {
    final titleController =
        TextEditingController(text: (task['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (task['description'] ?? '').toString());
    String priority = _isPriority(task) ? 'priority' : 'normal';
    final saved = await showModalBottomSheet<bool>(
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
                          child: Text(
                            'Edit Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task title',
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
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          priority =
                              priority == 'priority' ? 'normal' : 'priority';
                        });
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: priority == 'priority'
                              ? const Color(0xFFFFE4E6)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              priority == 'priority'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: priority == 'priority'
                                  ? const Color(0xFFE11D48)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Priority Task',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
      },
    );
    if (saved != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    await updateTask(
      id: task['id'],
      title: title,
      description: descriptionController.text.trim(),
      priority: priority,
    );
    if (!mounted) return;
    setState(() {});
  }
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 90),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5B2EFF),
            Color(0xFF8B2CF5),
            Color(0xFFB832D4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Welcome to',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const Text(
            'Hamkar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                icon: Icon(Icons.search_rounded, color: Colors.white70),
                hintText: 'Search task...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                suffixIcon: Icon(Icons.tune_rounded, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChips() {
    Widget filterItem(String label, IconData icon) {
      final selected = _selectedFilter == label;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C3AED) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFF7C3AED) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade800,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        filterItem('All', Icons.grid_view_rounded),
        filterItem('Priority', Icons.flag_rounded),
      ],
    );
  }
  Widget _buildBadge({
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
  Widget _buildSwipeTaskCard(Map<String, dynamic> task) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Slidable(
      key: ValueKey(task['id']),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.18, // 👈 smaller swipe width
          children: [
            CustomSlidableAction(
              onPressed: (_) async {
                await deleteTask(task['id']);
                if (!mounted) return;
                setState(() {});
              },
              backgroundColor: Colors.transparent,
              child: Container(
                width: 48, // 👈 smaller button
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(14), // 👈 softer corners
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20, // 👈 smaller icon
                ),
              ),
            ),
          ],
        ),
      child: GestureDetector(
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskPage(task: task),
            ),
          );

          if (updated == true && mounted) {
            setState(() {});
          }
        },
        child: _buildTaskCard(task),
      ),
    ),
  );
}

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['is_completed'] ?? false;
    final isPriority = _isPriority(task);
    final repeatType = task['repeat_type'] ?? 'none';
    final category = task['category'];
    return AnimatedScale(
      scale: isCompleted ? 0.97 : 1,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF22C55E)
                : isPriority
                    ? const Color(0xFFFB7185)
                    : Colors.grey.shade200,
            width: isCompleted || isPriority ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              activeColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: (value) async {
                if (value == null) return;
                await updateTaskCompletion(task['id'], value);
                if (!mounted) return;
                setState(() {});
              },
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFDCFCE7)
                    : isPriority
                        ? const Color(0xFFFFE4E6)
                        : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : isPriority
                        ? Icons.flag_rounded
                        : Icons.task_alt_rounded,
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : isPriority
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCompleted ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCompleted
                            ? Colors.grey.shade500
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _taskTime(task),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      children: [
                        if (isCompleted)
                          _buildBadge(
                            text: 'COMPLETED',
                            textColor: const Color(0xFF16A34A),
                            backgroundColor: const Color(0xFFDCFCE7),
                          ),
                        if (isPriority)
                          _buildBadge(
                            text: 'PRIORITY',
                            textColor: const Color(0xFFE11D48),
                            backgroundColor: const Color(0xFFFFE4E6),
                          ),
                        if (repeatType == 'daily')
                          _buildBadge(
                            text: 'DAILY',
                            textColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFFDBEAFE),
                          ),
                        if (category != null)
                          _buildBadge(
                            text: category.toString().toUpperCase(),
                            textColor: const Color(0xFF7C3AED),
                            backgroundColor: const Color(0xFFEDE9FE),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _selectedFilter == 'Priority'
            ? 'No priority tasks yet'
            : _searchQuery.isNotEmpty
                ? 'No task found'
                : 'No tasks yet',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> allTasks) {
    var tasks = _selectedFilter == 'Priority'
        ? allTasks.where((task) => _isPriority(task)).toList()
        : allTasks;
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        final description =
            (task['description'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery) ||
            description.contains(_searchQuery);
      }).toList();
    }
    return tasks;
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildHeader(),
            Positioned(
              top: 225,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(42),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Task",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchTasks(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                          final tasks = _applyFilters(allTasks);
                          if (tasks.isEmpty) {
                            return _buildEmptyState();
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 110),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              return _buildSwipeTaskCard(tasks[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskPage()),
          );
          if (!mounted) return;
          setState(() {});
        },
        backgroundColor: const Color(0xFF8B2CF5),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}