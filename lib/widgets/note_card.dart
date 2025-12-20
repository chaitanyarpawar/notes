import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/app_theme.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isArchived;
  final bool isSelectionMode;
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.isArchived = false,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  // Check if this note is a checklist
  bool get _isChecklist {
    return note.content.contains('☐') ||
        note.content.contains('☑') ||
        note.content == 'Checklist';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteColor = AppTheme.getNoteColor(note.color, isDark);
    final chipBg = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.8);
    final chipText = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: EdgeInsets.zero,
      color: isSelected
          ? noteColor.withValues(alpha: isDark ? 0.5 : 0.9)
          : noteColor.withValues(alpha: isDark ? 0.3 : 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with selection checkbox, checklist indicator and pin indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isSelectionMode)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => onTap(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      // Checklist indicator
                      if (_isChecklist)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.checklist,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (note.isPinned && !isArchived)
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),

              // Content preview: show on home cards (title + first lines)
              // Tighter constraints: checklist 3 lines, notes 5 lines
              if (note.content.isNotEmpty && note.content != 'Checklist') ...[
                if (note.title.isNotEmpty) const SizedBox(height: 8),
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: _isChecklist ? 13 : 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                    fontFamily: _isChecklist ? 'monospace' : null,
                  ),
                  maxLines: _isChecklist ? 3 : 5,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (note.content == 'Checklist') ...[
                if (note.title.isNotEmpty) const SizedBox(height: 8),
                Text(
                  '☐ Add your first item',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Footer with date and category
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(note.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: chipText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today ${_formatTime(date)}';
    } else if (noteDate == yesterday) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (now.difference(date).inDays < 7) {
      return '${_getDayName(date.weekday)} ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
