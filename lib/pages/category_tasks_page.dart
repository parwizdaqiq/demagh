import 'package:flutter/material.dart';
import '../main.dart';
import 'add_task_page.dart';
import '../widgets/premium_task_card.dart';

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
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
  }

  Widget _premiumTask(Map<String, dynamic> task) {
    return PremiumTaskCard(
      task: task,
      accentColor: widget.color,
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
      onDelete: () async {
        await deleteTask(task['id']);
        if (!mounted) return;
        setState(() {});
      },
      onCompletedChanged: (value) async {
        await updateTaskCompletion(task['id'], value);
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 36,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks added to ${widget.category} will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
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
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _premiumTask(tasks[index]);
            },
          );
        },
      ),
    );
  }
}