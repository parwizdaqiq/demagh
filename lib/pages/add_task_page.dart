import 'package:flutter/material.dart';
import '../main.dart';
import '../services/notification_service.dart';

class AddTaskPage extends StatefulWidget {
  final Map<String, dynamic>? task;

  const AddTaskPage({
    super.key,
    this.task,
  });

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _selectedPriority = 'normal';
  String _selectedRepeatType = 'none';

  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;

  int _reminderMinutesBefore = 0;

  List<String> _categories = [];

  bool get _isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    _fillEditData();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fillEditData() {
    final task = widget.task;
    if (task == null) return;

    _titleController.text = (task['title'] ?? '').toString();
    _descriptionController.text = (task['description'] ?? '').toString();

    _selectedCategory = task['category']?.toString();

    _selectedPriority =
        task['priority'] == 'priority' || task['priority'] == 'high'
            ? 'priority'
            : 'normal';

    _selectedRepeatType = task['repeat_type'] ?? 'none';

    _reminderMinutesBefore = task['reminder_minutes_before'] ?? 0;

    final dateValue = task['due_at'] ?? task['specific_date'];
    if (dateValue != null) {
      final parsed = DateTime.tryParse(dateValue.toString());
      if (parsed != null) {
        _selectedDueDate = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final timeValue = task['time'];
    if (timeValue != null && timeValue.toString().contains(':')) {
      final parts = timeValue.toString().split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    }
  }

  Future<void> _loadCategories() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('categories')
        .select('name')
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    final loadedCategories = List<Map<String, dynamic>>.from(response)
        .map((item) => item['name'].toString())
        .toList();

    if (!mounted) return;

    setState(() {
      _categories = loadedCategories;

      if (_selectedCategory != null &&
          !_categories.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
    });
  }

  Future<void> _openProjectSheet() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
              const SizedBox(height: 18),
              const Text(
                'Choose Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.folder_off_rounded),
                title: const Text(
                  'No project',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: _selectedCategory == null
                    ? const Icon(Icons.check_rounded, color: Color(0xFF7C3AED))
                    : null,
                onTap: () => Navigator.pop(context, null),
              ),
              ..._categories.map((category) {
                return ListTile(
                  leading: const Icon(
                    Icons.folder_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: _selectedCategory == category
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF7C3AED),
                        )
                      : null,
                  onTap: () => Navigator.pop(context, category),
                );
              }),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedCategory = selected;
    });
  }

  Future<void> _openReminderSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        Widget item(String title, int value) {
          final active = _reminderMinutesBefore == value;

          return ListTile(
            leading: Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: active ? const Color(0xFF7C3AED) : Colors.grey,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () => Navigator.pop(context, value),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
              const SizedBox(height: 18),
              const Text(
                'Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              item('At task time', 0),
              item('5 minutes before', 5),
              item('10 minutes before', 10),
              item('30 minutes before', 30),
              item('1 hour before', 60),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _reminderMinutesBefore = selected;
    });
  }

  Future<void> _pickDate() async {
    if (_selectedRepeatType == 'daily') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily tasks do not need a date')),
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: _selectedDueDate ?? DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDueDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  String? _formattedTime() {
    if (_selectedTime == null) return null;

    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  String _formattedDate() {
    if (_selectedDueDate == null) return 'Choose due date';

    return '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}';
  }

  String _reminderText() {
    if (_reminderMinutesBefore == 0) return 'At task time';
    if (_reminderMinutesBefore == 60) return '1 hour before';
    return '$_reminderMinutesBefore minutes before';
  }

  Future<void> _scheduleTaskNotification({
    required String taskId,
    required String title,
    required String description,
  }) async {
    if (_selectedTime == null) return;

    DateTime taskDateTime;

    if (_selectedRepeatType == 'daily') {
      final now = DateTime.now();

      taskDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (taskDateTime.isBefore(now)) {
        taskDateTime = taskDateTime.add(const Duration(days: 1));
      }
    } else {
      if (_selectedDueDate == null) return;

      taskDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    final notificationTime = taskDateTime.subtract(
      Duration(minutes: _reminderMinutesBefore),
    );

    final notificationId = taskId.hashCode.abs();

    await NotificationService.cancelNotification(notificationId);

    await NotificationService.scheduleNotification(
      id: notificationId,
      title: 'Task Reminder',
      body: description.isEmpty ? title : '$title\n$description',
      scheduledTime: notificationTime,
    );
  }

  Future<void> _saveTask() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title is required')),
      );
      return;
    }

    final taskData = {
      'title': title,
      'description': description,
      'category': _selectedCategory,
      'priority': _selectedPriority,
      'repeat_type': _selectedRepeatType,
      'user_id': user.id,
      'due_at': _selectedRepeatType == 'daily'
          ? null
          : _selectedDueDate?.toIso8601String(),
      'specific_date': _selectedRepeatType == 'daily'
          ? null
          : _selectedDueDate?.toIso8601String(),
      'time': _formattedTime(),
      'reminder_minutes_before': _reminderMinutesBefore,
    };

    String taskId;

    if (_isEditMode) {
      taskId = widget.task!['id'].toString();

      await supabase
          .from('tasks')
          .update(taskData)
          .eq('id', taskId)
          .eq('user_id', user.id);
    } else {
      final inserted = await supabase
          .from('tasks')
          .insert({
            ...taskData,
            'is_completed': false,
          })
          .select()
          .single();

      taskId = inserted['id'].toString();
    }

    await _scheduleTaskNotification(
      taskId: taskId,
      title: title,
      description: description,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _isEditMode ? 'Edit Task' : 'New Task',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF7C3AED)),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _projectSelector() {
    return GestureDetector(
      onTap: _openProjectSheet,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_rounded, color: Color(0xFF7C3AED)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _selectedCategory ?? 'No project',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: disabled ? Colors.grey : const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtitle ?? title,
                style: TextStyle(
                  color: disabled ? Colors.grey : const Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!disabled)
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required bool active,
    required String title,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? activeColor : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : inactiveIcon,
              color: active ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: active ? activeColor : const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _saveTask,
        icon: const Icon(Icons.check_rounded),
        label: Text(_isEditMode ? 'Save Changes' : 'Save Task'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeText =
        _selectedTime == null ? 'Choose time' : _selectedTime!.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
              child: Column(
                children: [
                  _inputField(
                    controller: _titleController,
                    hint: 'Task title',
                    icon: Icons.task_alt_rounded,
                  ),
                  _inputField(
                    controller: _descriptionController,
                    hint: 'Description',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  _projectSelector(),
                  _toggleTile(
                    active: _selectedPriority == 'priority',
                    title: 'Priority Task',
                    activeIcon: Icons.flag_rounded,
                    inactiveIcon: Icons.flag_outlined,
                    activeColor: const Color(0xFFE11D48),
                    onTap: () {
                      setState(() {
                        _selectedPriority = _selectedPriority == 'priority'
                            ? 'normal'
                            : 'priority';
                      });
                    },
                  ),
                  _toggleTile(
                    active: _selectedRepeatType == 'daily',
                    title: 'Repeat Daily',
                    activeIcon: Icons.repeat_rounded,
                    inactiveIcon: Icons.repeat_rounded,
                    activeColor: const Color(0xFF7C3AED),
                    onTap: () {
                      setState(() {
                        if (_selectedRepeatType == 'daily') {
                          _selectedRepeatType = 'none';
                        } else {
                          _selectedRepeatType = 'daily';
                          _selectedDueDate = null;
                        }
                      });
                    },
                  ),
                  _optionTile(
                    title: 'Choose due date',
                    subtitle: _selectedRepeatType == 'daily'
                        ? 'Daily task does not need date'
                        : _formattedDate(),
                    icon: Icons.calendar_month_rounded,
                    disabled: _selectedRepeatType == 'daily',
                    onTap: _pickDate,
                  ),
                  _optionTile(
                    title: 'Choose time',
                    subtitle: timeText,
                    icon: Icons.access_time_rounded,
                    onTap: _pickTime,
                  ),
                  _optionTile(
                    title: 'Reminder',
                    subtitle: _reminderText(),
                    icon: Icons.notifications_rounded,
                    onTap: _openReminderSheet,
                  ),
                  const SizedBox(height: 12),
                  _saveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}