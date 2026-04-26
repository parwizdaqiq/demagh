import 'package:flutter/material.dart';
import '../main.dart';

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
    setState(() {});
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
    setState(() {});
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final isCompleted = task['is_completed'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            activeColor: widget.color,
            onChanged: (value) {
              if (value == null) return;
              updateTaskCompletion(task['id'], value);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task['title'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            onPressed: () => deleteTask(task['id']),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.category),
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
              child: Text('No ${widget.category} tasks yet'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: tasks.map(_taskCard).toList(),
          );
        },
      ),
    );
  }
}