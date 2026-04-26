import 'package:flutter/material.dart';
import '../main.dart';
import 'category_tasks_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final List<String> categories = [
    'Personal',
    'Assignments',
    'Meet',
    'Job',
  ];

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  Color categoryColor(String category) {
    switch (category) {
      case 'Personal':
        return const Color(0xFF6366F1);
      case 'Assignments':
        return const Color(0xFFEC4899);
      case 'Meet':
        return const Color(0xFF22C55E);
      case 'Job':
        return const Color(0xFFD946EF);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Projects',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTasks(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];

              final count = tasks
                  .where((task) => task['category'] == category)
                  .length;

              final color = categoryColor(category);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryTasksPage(
                        category: category,
                        color: color,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$count Tasks',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}