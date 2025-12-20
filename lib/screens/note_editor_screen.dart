import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/color_selector.dart';
import '../utils/app_theme.dart';
import '../widgets/lined_paper.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final bool isChecklist;
  final String category;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.isChecklist = false,
    this.category = 'Personal',
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  Note? _currentNote;
  String? _currentNoteId; // Track the noteId to prevent duplicates
  NoteColor _selectedColor = NoteColor.yellow;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  String _selectedCategory = 'Personal';
  DateTime? _reminderTime;
  String? _lastSavedSignature;

  @override
  void initState() {
    super.initState();
    _initializeNote();
    _setupListeners();
  }

  void _initializeNote() {
    _selectedCategory = widget.category; // Set category from filter
    debugPrint('📝 NoteEditor: Initializing with category: ${widget.category}');
    debugPrint('📝 NoteEditor: _selectedCategory set to: $_selectedCategory');

    // If editing an existing note, load it
    if (widget.noteId != null && widget.noteId!.isNotEmpty) {
      _currentNoteId = widget.noteId;
      final notesProvider = context.read<NotesProvider>();
      _currentNote = notesProvider.getNoteById(_currentNoteId!);

      if (_currentNote != null) {
        _titleController.text = _currentNote!.title;
        _contentController.text = _currentNote!.content;
        _selectedColor = _currentNote!.color;
        _selectedCategory = _currentNote!.category;
        _reminderTime = _currentNote!.reminderTime;
        debugPrint(
            '📝 NoteEditor: Loaded existing note - Category: ${_currentNote!.category}');
      } else {
        debugPrint(
            '❌ NoteEditor: Could not find note with ID: ${widget.noteId}');
      }
    } else {
      // New note initialization
      if (widget.isChecklist) {
        _titleController.text = 'Checklist Title';
        _contentController.text = '☐ Item 1\n☐ Add more items';
        debugPrint(
            '📝 NoteEditor: Initialized as checklist with category: $_selectedCategory');
      } else {
        debugPrint(
            '📝 NoteEditor: Initialized as new note with category: $_selectedCategory');
      }
      // For new notes, _currentNoteId remains null and will be set on first save
    }
  }

  void _setupListeners() {
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }

    // Debounced auto-save - faster for better UX
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_hasUnsavedChanges && !_isSaving && mounted) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    await _saveNote(showSnackbar: false, isAutoSave: true);
  }

  Future<void> _saveNote(
      {bool showSnackbar = true, bool isAutoSave = false}) async {
    if (_isSaving) return; // Prevent multiple saves

    // Don't save empty notes
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      debugPrint('📝 NoteEditor: Skipping save - note is empty');
      if (showSnackbar && mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Nothing to save'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // For manual saves, unfocus to ensure controllers are up-to-date.
    // Avoid unfocus during auto-saves to prevent keyboard minimizing while typing.
    if (mounted && !isAutoSave) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      _isSaving = true;
    });

    final notesProvider = context.read<NotesProvider>();
    String actionText = 'Note saved';

    debugPrint(
        '📝 NoteEditor: Starting save - isAutoSave: $isAutoSave, category: $_selectedCategory');
    debugPrint('📝 NoteEditor: Title: "${_titleController.text.trim()}"');
    debugPrint(
        '📝 NoteEditor: Content length: ${_contentController.text.trim().length}');

    // Build a signature to avoid redundant saves when nothing changed
    String buildSignature() {
      final buf = StringBuffer()
        ..write(_titleController.text.trim())
        ..write('|')
        ..write(_contentController.text.trim())
        ..write('|')
        ..write(_selectedColor.index)
        ..write('|')
        ..write(_selectedCategory)
        ..write('|')
        ..write(_reminderTime?.millisecondsSinceEpoch ?? 0);
      return buf.toString();
    }

    final newSignature = buildSignature();
    if (_lastSavedSignature == newSignature) {
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      return;
    }

    try {
      if (_currentNoteId != null) {
        // Update existing note (either initially existing or created during this session)
        final noteToUpdate =
            _currentNote ?? notesProvider.getNoteById(_currentNoteId!);

        if (noteToUpdate != null) {
          debugPrint(
              '📝 NoteEditor: Updating existing note ID: $_currentNoteId');
          final updatedNote = noteToUpdate.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            color: _selectedColor,
            category: _selectedCategory, // ✅ Category preserved in update
            reminderTime: _reminderTime,
            clearReminder: _reminderTime == null,
          );

          await notesProvider.updateNote(updatedNote);
          _currentNote = updatedNote;
          actionText = 'Note updated';
          debugPrint(
              '✅ NoteEditor: Note updated successfully with category: ${updatedNote.category}');
        } else {
          debugPrint(
              '❌ NoteEditor: Could not find note to update with ID: $_currentNoteId');
        }
      } else {
        // Create new note (only when noteId is null)
        debugPrint(
            '📝 NoteEditor: Creating new note with category: $_selectedCategory');
        final newNote = await notesProvider.createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          category: _selectedCategory, // ✅ Category included in create
          reminderTime: _reminderTime,
        );

        // Set the noteId and current note so all subsequent saves will update
        _currentNoteId = newNote.id;
        _currentNote = newNote;
        actionText = 'Note created';
        debugPrint(
            '✅ NoteEditor: Note created successfully - ID: ${newNote.id}, Category: ${newNote.category}');

        // Increment note count only when actually creating a new note
        if (mounted) {
          final settingsProvider = context.read<SettingsProvider>();
          await settingsProvider.incrementNoteCount();
        }
      }
    } catch (e) {
      // Handle any errors during save
      debugPrint('❌ NoteEditor: Error saving note: $e');
      // Removed failure SnackBar entirely per user request
    }

    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
        _lastSavedSignature = newSignature;
      });

      if (showSnackbar) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(actionText),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      debugPrint('✅ NoteEditor: Save completed - $actionText');
    }
  }

  Future<void> _deleteNote() async {
    if (_currentNote != null) {
      final confirmed = await _showDeleteConfirmation();
      if (confirmed == true && mounted) {
        final notesProvider = context.read<NotesProvider>();
        await notesProvider.deleteNote(_currentNote!.id);

        if (mounted) {
          final navigator = Navigator.of(context);
          navigator.pop();
          if (mounted) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Note deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final subject = title.isEmpty ? 'Note' : title;
    final text = content.isEmpty ? subject : '$subject\n\n$content';
    try {
      await Share.share(text, subject: subject);
    } catch (_) {}
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackButton() async {
    // Auto-save before going back if there are unsaved changes
    if (_hasUnsavedChanges && !_isSaving) {
      await _saveNote(showSnackbar: false, isAutoSave: true);
    }
    if (mounted) {
      // Clear any search so newly saved notes are visible
      try {
        context.read<NotesProvider>().clearSearch();
      } catch (_) {}
      // Prefer explicit navigation to home to ensure list rebuild
      context.go('/home');
    }
  }

  Future<void> _handleManualSave() async {
    await _saveNote(showSnackbar: true, isAutoSave: false);
    // Navigate back to home screen after successful save
    if (mounted) {
      try {
        context.read<NotesProvider>().clearSearch();
      } catch (_) {}
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteColor = AppTheme.getNoteColor(_selectedColor, isDark);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: noteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: _handleBackButton,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black54),
            onPressed: _shareNote,
          ),
          // Mic removed: text-only input UI
          // Only show delete button for existing notes, keep it simple
          if (_currentNoteId != null && _currentNote != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black54),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: Column(
        children: [
          // Category indicator for new notes
          if (_currentNoteId == null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.label_outline,
                    color: Color(0xFFFF9500),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Creating in: $_selectedCategory',
                    style: const TextStyle(
                      color: Color(0xFFFF9500),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Title field - separate at the top
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: InputDecoration(
                hintText: widget.isChecklist ? 'Checklist Title' : 'Title',
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // Reminder row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.alarm),
                  label: const Text('Set Reminder'),
                ),
                const SizedBox(width: 12),
                if (_reminderTime != null)
                  Flexible(
                    child: Text(
                      _formatReminder(_reminderTime!),
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                if (_reminderTime != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearReminder,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content field - main area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: LinedPaper(
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: InputDecoration(
                    hintText: widget.isChecklist
                        ? '☐ Add items...'
                        : 'Start typing...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom bar with actions
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewPadding.bottom > 0 ? 12 : 16,
          ),
          child: Row(
            children: [
              // Color picker button
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Category button with selected category display
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined,
                          color: Colors.black54, size: 18),
                      SizedBox(width: 8),
                      // Selected category label
                      // (Tap to change category)
                      // Using a const Text style for consistency
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Text(
                _selectedCategory,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Save button - now always visible and functional
              GestureDetector(
                onTap: _isSaving ? null : _handleManualSave,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isSaving ? Colors.grey : const Color(0xFFFF9500),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Mic input removed: no floating action button
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ColorSelector(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                    _hasUnsavedChanges = true;
                  });
                  Navigator.pop(context);
                  // Auto-save after color change
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_hasUnsavedChanges && !_isSaving && mounted) {
                      _autoSave();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    final categories = ['Personal', 'Work', 'Ideas', 'Important'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...categories.map((category) {
                return ListTile(
                  leading: _selectedCategory == category
                      ? const Icon(Icons.check, color: Color(0xFF007AFF))
                      : null,
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(context);
                    // Auto-save after category change
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_hasUnsavedChanges && !_isSaving && mounted) {
                        _autoSave();
                      }
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _reminderTime = dt;
      _hasUnsavedChanges = true;
    });
    // Auto-save after reminder set
    if (!mounted) return;
    await _autoSave();
  }

  String _formatReminder(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = weekdays[d.weekday - 1];
    final mn = months[d.month - 1];
    return '$wd, ${d.day} $mn ${d.year}  ${two(hour)}:${two(d.minute)} $ampm';
  }

  Future<void> _clearReminder() async {
    setState(() {
      _reminderTime = null;
      _hasUnsavedChanges = true;
    });
    await _autoSave();
  }
}
