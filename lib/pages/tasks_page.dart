import 'package:flutter/material.dart';
import '../main.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  DateTime _selectedDay = DateTime.now();

  final List<String> _months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final List<String> _weekDays = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateTaskCompletion(String id, bool value) async {
    await supabase.from('tasks').update({'is_completed': value}).eq('id', id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openCalendarPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDay = _selectedDay.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDay = _selectedDay.add(const Duration(days: 1));
    });
  }

  String _friendlyDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    final diff = selected.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';

    return '${_months[_selectedDay.month - 1]} ${_selectedDay.day}, ${_selectedDay.year}';
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final check = DateTime(day.year, day.month, day.day);

    final diff = check.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';

    return _weekDays[day.weekday - 1];
  }

  DateTime? _getTaskDate(Map<String, dynamic> task) {
    final dateValue = task['due_at'] ?? task['specific_date'];
    if (dateValue == null) return null;

    final parsed = DateTime.tryParse(dateValue.toString());
    if (parsed == null) return null;

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> _tasksForDay(
    List<Map<String, dynamic>> tasks,
    DateTime day,
  ) {
    return tasks.where((task) {
      if (task['repeat_type'] == 'daily') return true;

      final taskDate = _getTaskDate(task);
      if (taskDate == null) return false;

      return _isSameDay(taskDate, day);
    }).toList();
  }

  List<DateTime> _daysAroundSelectedDay() {
    return List.generate(5, (index) {
      return DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + index - 2,
      );
    });
  }

  String _taskTime(Map<String, dynamic> task) {
    final time = task['time'];
    if (time == null || time.toString().isEmpty) return 'No time';
    return time.toString();
  }

  int _hourFromTask(Map<String, dynamic> task) {
    final time = task['time'];
    if (time == null || !time.toString().contains(':')) return 99;

    final parts = time.toString().split(':');
    return int.tryParse(parts[0]) ?? 99;
  }

  Widget _dateCard(DateTime day) {
    final selected = _isSameDay(day, _selectedDay);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _dayLabel(day),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskTimelineCard(Map<String, dynamic> task) {
    final isCompleted = task['is_completed'] ?? false;
    final repeatType = task['repeat_type'] ?? 'none';
    final isPriority =
        task['priority'] == 'priority' || task['priority'] == 'high';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                _taskTime(task),
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await updateTaskCompletion(task['id'], !isCompleted);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPriority
                      ? const Color(0xFF7C3AED)
                      : isCompleted
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isPriority ? Colors.white : const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCompleted ? 0.55 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] ?? '',
                              style: TextStyle(
                                color: isPriority
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              repeatType == 'daily'
                                  ? '${_taskTime(task)} • Daily'
                                  : _taskTime(task),
                              style: TextStyle(
                                color: isPriority
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 46),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Calendar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  child: IconButton(
                    onPressed: _openCalendarPicker,
                    icon: const Icon(Icons.calendar_month_rounded),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                IconButton(
                  onPressed: _goToPreviousDay,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: Colors.white,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _daysAroundSelectedDay().map(_dateCard).toList(),
                  ),
                ),
                IconButton(
                  onPressed: _goToNextDay,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: Colors.white,
                ),
              ],
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTasks(),
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final selectedTasks = _tasksForDay(allTasks, _selectedDay)
            ..sort((a, b) => _hourFromTask(a).compareTo(_hourFromTask(b)));

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _header(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _friendlyDateLabel(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${selectedTasks.length} tasks',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: selectedTasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks on this date',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) {
                          return _taskTimelineCard(selectedTasks[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}