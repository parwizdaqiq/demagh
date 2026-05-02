import 'package:flutter/material.dart';
import '../main.dart';
import 'category_tasks_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final List<String> _colorOptions = [
    '#7C3AED',
    '#F97316',
    '#06B6D4',
    '#22C55E',
    '#EC4899',
    '#6366F1',
    '#EF4444',
    '#F59E0B',
  ];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _tasks = [];

  bool _isFirstLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(firstLoad: true);
    });
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF7C3AED);

    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('categories')
        .select('name, color')
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response =
        await supabase.from('tasks').select().eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _loadData({bool firstLoad = false}) async {
    if (!mounted) return;

    if (!firstLoad) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final categories = await fetchCategories();
      final tasks = await fetchTasks();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _tasks = tasks;
        _isFirstLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFirstLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load projects: $e')),
      );
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    String selectedColor = _colorOptions.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Project'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Project name',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((hex) {
                        final color = _colorFromHex(hex);
                        final selected = selectedColor == hex;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = hex;
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.black : Colors.white,
                                width: selected ? 3 : 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(context, {
                      'name': name,
                      'color': selectedColor,
                    });
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isRefreshing = true);

    await supabase.from('categories').insert({
      'name': result['name'],
      'color': result['color'],
      'user_id': user.id,
    });

    await _loadData();
  }

  Future<void> _editCategory(Map<String, dynamic> categoryData) async {
    final oldName = categoryData['name'].toString();
    final controller = TextEditingController(text: oldName);
    String selectedColor = categoryData['color'] ?? _colorOptions.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Project'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Project name',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((hex) {
                        final color = _colorFromHex(hex);
                        final selected = selectedColor == hex;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = hex;
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.black : Colors.white,
                                width: selected ? 3 : 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(context, {
                      'name': name,
                      'color': selectedColor,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final newName = result['name']!;
    final newColor = result['color']!;

    setState(() => _isRefreshing = true);

    await supabase
        .from('categories')
        .update({
          'name': newName,
          'color': newColor,
        })
        .eq('user_id', user.id)
        .eq('name', oldName);

    await supabase
        .from('tasks')
        .update({'category': newName})
        .eq('user_id', user.id)
        .eq('category', oldName);

    await _loadData();
  }

  Future<void> _deleteCategory(String category) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isRefreshing = true);

    await supabase
        .from('categories')
        .delete()
        .eq('user_id', user.id)
        .eq('name', category);

    await _loadData();
  }

  int _taskCount(String category) {
    return _tasks.where((task) => task['category'] == category).length;
  }

  Widget _projectCard({
    required Map<String, dynamic> categoryData,
    required int count,
  }) {
    final category = categoryData['name'].toString();
    final color = _colorFromHex(categoryData['color']);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryTasksPage(
              category: category,
              color: color,
            ),
          ),
        );

        if (!mounted) return;
        await _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.folder_rounded,
                size: 70,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder, color: Colors.white),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _editCategory(categoryData),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _deleteCategory(category),
                      child: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count Tasks',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _updatingBadge() {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Updating...',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'No projects yet',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _grid() {
    if (_categories.isEmpty) return _emptyState();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final categoryData = _categories[index];
        final category = categoryData['name'].toString();

        return _projectCard(
          categoryData: categoryData,
          count: _taskCount(category),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
      floatingActionButton: FloatingActionButton(
        onPressed: _isRefreshing ? null : _addCategory,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          _grid(),
          if (_isRefreshing) _updatingBadge(),
        ],
      ),
    );
  }
}