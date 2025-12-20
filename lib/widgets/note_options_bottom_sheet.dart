import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/checklist_provider.dart';

class NoteOptionsBottomSheet extends StatelessWidget {
  final Note note;

  const NoteOptionsBottomSheet({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this note represents a checklist
    final bool isChecklist = note.content.contains('☐') ||
        note.content.contains('☑') ||
        note.content == 'Checklist';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Note header (title only)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'Untitled Note',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options
          _buildOption(
            context,
            icon: Icons.edit,
            title: 'Edit',
            onTap: () {
              Navigator.of(context).pop();
              if (isChecklist) {
                context.push('/checklist/${note.id}');
              } else {
                context.push('/note/${note.id}');
              }
            },
          ),

          _buildOption(
            context,
            icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            title: note.isPinned ? 'Unpin' : 'Pin',
            onTap: () async {
              final notesProvider = context.read<NotesProvider>();
              await notesProvider.togglePin(note.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(note.isPinned ? 'Note unpinned' : 'Note pinned'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          _buildOption(
            context,
            icon: Icons.copy,
            title: 'Duplicate',
            onTap: () async {
              final notesProvider = context.read<NotesProvider>();
              final checklistProvider = context.read<ChecklistProvider>();
              await notesProvider.duplicateNote(note.id);
              // If checklist, clone its items to the new copy
              try {
                final isChecklist = note.content.contains('☐') ||
                    note.content.contains('☑') ||
                    note.content == 'Checklist';
                if (isChecklist) {
                  // Find the newly created note by title suffix
                  final newTitle = '${note.title} (Copy)';
                  final all = notesProvider.allNotes;
                  final created = all.firstWhere(
                    (n) =>
                        n.title == newTitle &&
                        n.updatedAt.isAfter(note.updatedAt),
                    orElse: () => note,
                  );
                  if (created.id != note.id) {
                    await checklistProvider.cloneChecklistItems(
                        note.id, created.id);
                  }
                }
              } catch (_) {}
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note duplicated'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          _buildOption(
            context,
            icon: Icons.share_outlined,
            title: 'Share',
            onTap: () async {
              final title = note.title.isNotEmpty ? note.title : 'Note';
              final content = note.content.trim();
              final text = content.isEmpty ? title : '$title\n\n$content';
              await Share.share(text, subject: title);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),

          _buildOption(
            context,
            icon: Icons.delete_outline,
            title: 'Delete',
            textColor: Colors.red,
            onTap: () => _showDeleteConfirmation(context),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final notesProvider = context.read<NotesProvider>();
              await notesProvider.deleteNote(note.id);

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
