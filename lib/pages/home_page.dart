import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';
import 'add_task_page.dart';
import '../widgets/premium_task_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';

  List<Map<String, dynamic>> _tasks = [];
  bool _isFirstLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks(firstLoad: true);
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

  Future<void> _loadTasks({bool firstLoad = false}) async {
    if (!mounted) return;

    if (!firstLoad) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final data = await fetchTasks();

      if (!mounted) return;

      setState(() {
        _tasks = data;
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
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  Future<void> updateTaskCompletion(String id, bool value) async {
    await supabase.from('tasks').update({'is_completed': value}).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await supabase.from('tasks').delete().eq('id', id);
  }

  bool _isPriority(Map<String, dynamic> task) {
    return task['priority'] == 'priority' || task['priority'] == 'high';
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> allTasks) {
    var tasks = _selectedFilter == 'Priority'
        ? allTasks.where((task) => _isPriority(task)).toList()
        : List<Map<String, dynamic>>.from(allTasks);

    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        final description =
            (task['description'] ?? '').toString().toLowerCase();

        return title.contains(_searchQuery) ||
            description.contains(_searchQuery);
      }).toList();
    }

    tasks.sort((a, b) {
      if (_isPriority(a) && !_isPriority(b)) return -1;
      if (!_isPriority(a) && _isPriority(b)) return 1;

      final ta = (a['time'] ?? '99:99').toString();
      final tb = (b['time'] ?? '99:99').toString();

      return ta.compareTo(tb);
    });

    return tasks;
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Text(
            _selectedFilter == 'Priority'
                ? 'No priority tasks'
                : _searchQuery.isNotEmpty
                    ? 'No task found'
                    : 'No tasks yet',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task and it will appear here.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  Widget _premiumTask(Map<String, dynamic> task) {
    return PremiumTaskCard(
      task: task,
      accentColor: const Color(0xFF7C3AED),
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTaskPage(task: task),
          ),
        );

        if (updated == true && mounted) {
          await _loadTasks();
        }
      },
      onDelete: () async {
        await deleteTask(task['id']);
        if (!mounted) return;
        await _loadTasks();
      },
      onCompletedChanged: (value) async {
        await updateTaskCompletion(task['id'], value);
        if (!mounted) return;
        await _loadTasks();
      },
    );
  }

  Widget _taskList() {
    final filteredTasks = _applyFilters(_tasks);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            return _premiumTask(filteredTasks[index]);
          },
        ),
        if (_isRefreshing) _updatingBadge(),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      child: _taskList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        onPressed: _isRefreshing
            ? null
            : () async {
                final added = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTaskPage()),
                );

                if (added == true && mounted) {
                  await _loadTasks();
                }
              },
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}