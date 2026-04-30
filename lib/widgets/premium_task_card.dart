import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PremiumTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onCompletedChanged;

  const PremiumTaskCard({
    super.key,
    required this.task,
    required this.accentColor,
    required this.onTap,
    required this.onDelete,
    required this.onCompletedChanged,
  });

  static const Color primary = Color(0xFF7C3AED);
  static const Color primarySoft = Color(0xFFF3E8FF);

  static const Color priority = Color(0xFFEF4444);
  static const Color prioritySoft = Color(0xFFFFE4E6);

  static const Color completed = Color(0xFF16A34A);
  static const Color completedSoft = Color(0xFFDCFCE7);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueSoft = Color(0xFFDBEAFE);

  static const Color textDark = Color(0xFF111827);

  bool get isCompleted => task['is_completed'] ?? false;

  bool get isPriority {
    return task['priority'] == 'priority' || task['priority'] == 'high';
  }

  String get time {
    final value = task['time'];
    if (value == null || value.toString().isEmpty) return 'No time';
    return value.toString();
  }

  String? get date {
    final value = task['due_at'] ?? task['specific_date'];
    if (value == null) return null;

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;

    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String get repeatType => task['repeat_type'] ?? 'none';

  String? get category => task['category']?.toString();

  Color get mainColor {
    if (isCompleted) return completed;
    if (isPriority) return priority;
    return primary;
  }

  Color get softColor {
    if (isCompleted) return completedSoft;
    if (isPriority) return prioritySoft;
    return primarySoft;
  }

  Widget _badge({
    required String text,
    required Color color,
    required Color background,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _card() {
    return AnimatedScale(
      scale: isCompleted ? 0.985 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: mainColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: mainColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 68,
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(width: 12),

            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onCompletedChanged(!isCompleted);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isCompleted ? completed : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: mainColor.withValues(alpha: 0.45),
                    width: 1.6,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('checked'),
                          color: Colors.white,
                          size: 20,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey('unchecked'),
                          color: mainColor.withValues(alpha: 0.55),
                          size: 18,
                        ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isCompleted
                      ? Icons.done_all_rounded
                      : isPriority
                          ? Icons.flag_rounded
                          : Icons.task_alt_rounded,
                  key: ValueKey(
                    isCompleted
                        ? 'completed'
                        : isPriority
                            ? 'priority'
                            : 'normal',
                  ),
                  color: mainColor,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: isCompleted ? 0.72 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCompleted ? Colors.grey.shade700 : textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    Wrap(
                      children: [
                        if (isCompleted)
                          _badge(
                            text: 'DONE',
                            color: completed,
                            background: Colors.white,
                          ),
                        if (isPriority)
                          _badge(
                            text: 'PRIORITY',
                            color: priority,
                            background: Colors.white,
                          ),
                        if (repeatType == 'daily')
                          _badge(
                            text: 'DAILY',
                            color: blue,
                            background: Colors.white,
                          ),
                        if (date != null && repeatType != 'daily')
                          _badge(
                            text: 'DATE: $date',
                            color: primary,
                            background: Colors.white,
                          ),
                        if (category != null && category!.isNotEmpty)
                          _badge(
                            text: category!.toUpperCase(),
                            color: primary,
                            background: Colors.white,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            Icon(
              Icons.chevron_right_rounded,
              color: mainColor.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Slidable(
        key: ValueKey(task['id']),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.18,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onDelete();
              },
              backgroundColor: Colors.transparent,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: priority,
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
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: onTap,
          child: _card(),
        ),
      ),
    );
  }
}