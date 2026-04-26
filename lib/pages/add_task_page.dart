import 'package:flutter/material.dart';
import '../main.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Personal';
  String _selectedPriority = 'normal';
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;

  final List<String> _categories = [
    'Personal',
    'Assignments',
    'Meet',
    'Job',
  ];

final List<String> _priorities = [
  'normal',
  'priority'
];

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
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

    await supabase.from('tasks').insert({
      'title': title,
      'description': description,
      'category': _selectedCategory,
      'priority': _selectedPriority,
      'user_id': user.id,
      'is_completed': false,
      'due_at': _selectedDueDate?.toIso8601String(),
      'time': _selectedTime == null
          ? null
          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
    });

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget _inputBox({
    required String label,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueDateText = _selectedDueDate == null
        ? 'Choose due date'
        : '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}';

    final timeText = _selectedTime == null
        ? 'Choose time'
        : _selectedTime!.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Task'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _inputBox(
              label: 'Title',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  border: InputBorder.none,
                ),
              ),
            ),

            _inputBox(
              label: 'Description',
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: InputBorder.none,
                ),
              ),
            ),

            _inputBox(
              label: 'Category',
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: InputBorder.none,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),

            _inputBox(
              label: 'Priority',
              child: DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: InputBorder.none,
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
            ),

            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(Icons.calendar_month_rounded),
              title: Text(dueDateText),
              onTap: _pickDate,
            ),

            const SizedBox(height: 12),

            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(Icons.access_time_rounded),
              title: Text(timeText),
              onTap: _pickTime,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}