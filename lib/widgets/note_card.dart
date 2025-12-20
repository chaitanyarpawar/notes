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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (note.isPinned && !isArchived)
                    Icon(
                      Icons.push_pin,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Title
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Content preview - use Expanded to fill available space and clip overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildContentPreview(),
                ),
              ),

              // Footer with category chip at bottom-right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: chipText,
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

  Widget _buildContentPreview() {
    if (note.content.isEmpty || note.content == 'Checklist') {
      if (note.content == 'Checklist') {
        return Text(
          '☐ Add your first item',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
      return const SizedBox.shrink();
    }

    return Text(
      note.content,
      style: TextStyle(
        fontSize: _isChecklist ? 11 : 12,
        color: Colors.grey.shade700,
        height: 1.3,
        fontFamily: _isChecklist ? 'monospace' : null,
      ),
      maxLines: _isChecklist ? 3 : 4,
      overflow: TextOverflow.ellipsis,
    );
  }
}
