import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../main.dart';
import 'add_task_page.dart';

class CategoryTasksPage extends StatefulWidget {
  final String category;
  final Color color;

  const CategoryTasksPage({
    super.key,
    required this.category,
    required this.color,
  });

  @override
  State<CategoryTasksPage> createState() => _CategoryTasksPageState();
}

class _CategoryTasksPageState extends State<CategoryTasksPage> {
  Future<List<Map<String, dynamic>>> fetchCategoryTasks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .eq('category', widget.category)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateTaskCompletion(String id, bool value) async {
    await supabase.from('tasks').update({'is_completed': value}).eq('id', id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
    if (!mounted) return;
    setState(() {});
  }

  bool _isPriority(Map<String, dynamic> task) {
    return task['priority'] == 'priority' || task['priority'] == 'high';
  }

  String _taskTime(Map<String, dynamic> task) {
    final time = task['time'];
    if (time == null || time.toString().isEmpty) return 'No time';
    return time.toString();
  }

  String? _taskDate(Map<String, dynamic> task) {
    final dateValue = task['due_at'] ?? task['specific_date'];
    if (dateValue == null) return null;

    final parsed = DateTime.tryParse(dateValue.toString());
    if (parsed == null) return null;

    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _badge({
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

  Widget _swipeTaskCard(Map<String, dynamic> task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Slidable(
        key: ValueKey(task['id']),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.18,
          children: [
            CustomSlidableAction(
              onPressed: (_) async {
                await deleteTask(task['id']);
              },
              backgroundColor: Colors.transparent,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
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
          child: _taskCard(task),
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final isCompleted = task['is_completed'] ?? false;
    final isPriority = _isPriority(task);
    final repeatType = task['repeat_type'] ?? 'none';
    final date = _taskDate(task);

    return AnimatedScale(
      scale: isCompleted ? 0.97 : 1,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 7),
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
              onChanged: (value) {
                if (value == null) return;
                updateTaskCompletion(task['id'], value);
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
                        : widget.color.withValues(alpha: 0.14),
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
                        : widget.color,
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
                          _badge(
                            text: 'COMPLETED',
                            textColor: const Color(0xFF16A34A),
                            backgroundColor: const Color(0xFFDCFCE7),
                          ),
                        if (isPriority)
                          _badge(
                            text: 'PRIORITY',
                            textColor: const Color(0xFFE11D48),
                            backgroundColor: const Color(0xFFFFE4E6),
                          ),
                        if (repeatType == 'daily')
                          _badge(
                            text: 'DAILY',
                            textColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFFDBEAFE),
                          ),
                        if (date != null && repeatType != 'daily')
                          _badge(
                            text: 'DATE: $date',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCategoryTasks(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tasks.isEmpty) {
            return Center(
              child: Text(
                'No ${widget.category} tasks yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _swipeTaskCard(tasks[index]);
            },
          );
        },
      ),
    );
  }
}