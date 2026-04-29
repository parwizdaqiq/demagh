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

  String? _selectedCategory;
  String _selectedPriority = 'normal';
  String _selectedRepeatType = 'none';

  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
      _selectedCategory =
          loadedCategories.isNotEmpty ? loadedCategories.first : null;
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

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create/select a project first')),
      );
      return;
    }

    await supabase.from('tasks').insert({
      'title': title,
      'description': description,
      'category': _selectedCategory,
      'priority': _selectedPriority,
      'repeat_type': _selectedRepeatType,
      'user_id': user.id,
      'is_completed': false,
      'due_at': _selectedRepeatType == 'daily'
          ? null
          : _selectedDueDate?.toIso8601String(),
      'specific_date': _selectedRepeatType == 'daily'
          ? null
          : _selectedDueDate?.toIso8601String(),
      'time': _selectedTime == null
          ? null
          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _inputBox({required Widget child}) {
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

    final timeText =
        _selectedTime == null ? 'Choose time' : _selectedTime!.format(context);

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
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  border: InputBorder.none,
                ),
              ),
            ),

            _inputBox(
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: InputBorder.none,
                ),
              ),
            ),

            _categories.isEmpty
                ? _inputBox(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'No projects available. Create one first from Projects page.',
                      ),
                    ),
                  )
                : _inputBox(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        border: InputBorder.none,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),

            _inputBox(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPriority =
                        _selectedPriority == 'priority' ? 'normal' : 'priority';
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPriority == 'priority'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _selectedPriority == 'priority'
                            ? const Color(0xFFE11D48)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Priority Task',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _inputBox(
              child: InkWell(
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
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _selectedRepeatType == 'daily'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _selectedRepeatType == 'daily'
                            ? const Color(0xFF7C3AED)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Repeat Daily',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            ListTile(
              tileColor: _selectedRepeatType == 'daily'
                  ? Colors.grey.shade200
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: Icon(
                Icons.calendar_month_rounded,
                color: _selectedRepeatType == 'daily'
                    ? Colors.grey
                    : Colors.black,
              ),
              title: Text(
                _selectedRepeatType == 'daily'
                    ? 'Daily task (no date needed)'
                    : dueDateText,
                style: TextStyle(
                  color: _selectedRepeatType == 'daily'
                      ? Colors.grey
                      : Colors.black,
                ),
              ),
              onTap: _selectedRepeatType == 'daily' ? null : _pickDate,
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