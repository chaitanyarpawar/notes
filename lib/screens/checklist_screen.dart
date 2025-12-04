import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../models/checklist_item.dart';
import '../providers/notes_provider.dart';
import '../providers/checklist_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/color_selector.dart';
import '../utils/app_theme.dart';

class ChecklistScreen extends StatefulWidget {
  final String? noteId;
  final String category;

  const ChecklistScreen({
    super.key,
    this.noteId,
    this.category = 'Personal',
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _itemControllers = [];

  Note? _currentNote;
  NoteColor _selectedColor = NoteColor.blue;
  String _selectedCategory = 'Personal';
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChecklist();
    });
  }

  void _initializeChecklist() async {
    _selectedCategory = widget.category; // Initialize with passed category
    debugPrint(
        '📋 ChecklistScreen: Initializing checklist with category: ${widget.category}');

    if (widget.noteId != null) {
      final notesProvider = context.read<NotesProvider>();
      final checklistProvider = context.read<ChecklistProvider>();

      _currentNote = notesProvider.getNoteById(widget.noteId!);

      if (_currentNote != null) {
        _titleController.text = _currentNote!.title;
        _selectedColor = _currentNote!.color;
        _selectedCategory = _currentNote!.category;
        _isEditing = true;

        // Load checklist items from database
        await checklistProvider.loadChecklistItems(_currentNote!.id);
        if (mounted) {
          _createControllers(checklistProvider.items);
        }
        debugPrint(
            '📋 ChecklistScreen: Loaded existing checklist with ${checklistProvider.items.length} items, category: ${_currentNote!.category}');
      }
    } else {
      // For new checklists, clear any previous items and start fresh
      final checklistProvider = context.read<ChecklistProvider>();
      checklistProvider.clearItems();

      // Clear any existing controllers
      for (final controller in _itemControllers) {
        controller.dispose();
      }
      _itemControllers.clear();

      debugPrint(
          '📋 ChecklistScreen: Initialized new checklist with category: ${widget.category}');
    }

    _titleController.addListener(_onTextChanged);
  }

  void _createControllers(List<ChecklistItem> items) {
    // Only create controllers if count has changed or we have no controllers
    if (_itemControllers.length != items.length) {
      // Clear existing controllers
      for (final controller in _itemControllers) {
        controller.dispose();
      }
      _itemControllers.clear();

      // Create controllers for existing items
      for (final item in items) {
        final controller = TextEditingController(text: item.text);
        controller.addListener(_onTextChanged);
        _itemControllers.add(controller);
      }
    }
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _toggleItemCompletion(int index) async {
    final checklistProvider = context.read<ChecklistProvider>();
    final item = checklistProvider.items[index];

    if (item.id != null) {
      await checklistProvider.updateChecklistItemStatus(
        item.id!,
        !item.isChecked,
      );
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _addNewItem() async {
    final checklistProvider = context.read<ChecklistProvider>();

    if (_currentNote == null && !_isEditing) {
      // Need to create parent note first for new checklists
      await _saveChecklist();
    }

    if (_currentNote != null) {
      debugPrint(
          '📋 ChecklistScreen: Adding new item to checklist ${_currentNote!.id}');
      final newItem = await checklistProvider.addChecklistItem(
        _currentNote!.id,
        '',
      );

      if (newItem != null) {
        final controller = TextEditingController(text: '');
        controller.addListener(_onTextChanged);
        _itemControllers.add(controller);

        setState(() {
          _hasUnsavedChanges = true;
        });

        // Focus on the new item after a short delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _itemControllers.isNotEmpty) {
            // Try to focus the last added text field
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                final lastIndex = _itemControllers.length - 1;
                if (lastIndex >= 0 && lastIndex < _itemControllers.length) {
                  // Can't directly focus controller, but the UI will auto-focus new empty fields
                  setState(() {});
                }
              }
            });
          }
        });
        debugPrint(
            '✅ ChecklistScreen: Added new item, total items: ${checklistProvider.items.length}');
      }
    } else {
      debugPrint('⚠️ ChecklistScreen: Cannot add item - no current note');
    }
  }

  Future<void> _removeItem(int index) async {
    final checklistProvider = context.read<ChecklistProvider>();
    final item = checklistProvider.items[index];

    if (item.id != null) {
      await checklistProvider.deleteChecklistItem(item.id!);

      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);

      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _updateItemText(int index, String text) async {
    final checklistProvider = context.read<ChecklistProvider>();
    if (index < checklistProvider.items.length) {
      final item = checklistProvider.items[index];
      if (item.id != null && text != item.text) {
        // Use provider method but without immediate notification to prevent text loss
        await checklistProvider.updateChecklistItemTextSilent(item.id!, text);
      }
    }
  }

  Future<void> _saveChecklist() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Checklist'
        : _titleController.text.trim();

    final notesProvider = context.read<NotesProvider>();
    final checklistProvider = context.read<ChecklistProvider>();

    // Update item texts from controllers first
    final items = checklistProvider.items;
    for (int i = 0; i < items.length && i < _itemControllers.length; i++) {
      final text = _itemControllers[i].text.trim();
      if (text.isNotEmpty && text != items[i].text) {
        await _updateItemText(i, text);
      }
    }

    // Create content representation for display on home screen
    final updatedItems = checklistProvider.items;
    String contentPreview = '';
    if (updatedItems.isNotEmpty) {
      // Show first few items as preview
      final previewItems = updatedItems.take(3).map((item) {
        final checkbox = item.isChecked ? '☑' : '☐';
        return '$checkbox ${item.text.isNotEmpty ? item.text : 'New item'}';
      }).toList();

      contentPreview = previewItems.join('\n');
      if (updatedItems.length > 3) {
        contentPreview += '\n... and ${updatedItems.length - 3} more items';
      }
    } else {
      contentPreview = '☐ Add your first item';
    }

    if (_isEditing && _currentNote != null) {
      // Update existing note with checklist content
      final updatedNote = _currentNote!.copyWith(
        title: title,
        content: contentPreview, // Show actual checklist items
        color: _selectedColor,
        category: _selectedCategory,
      );
      await notesProvider.updateNote(updatedNote);
      _currentNote = updatedNote;
      debugPrint(
          '✅ ChecklistScreen: Updated checklist note with ${updatedItems.length} items');
    } else if (!_isSaving) {
      // Create new note first
      setState(() {
        _isSaving = true;
      });

      debugPrint(
          '📋 ChecklistScreen: About to create note with category: $_selectedCategory');
      final newNote = await notesProvider.createNote(
        title: title,
        content: contentPreview, // Show actual checklist items
        color: _selectedColor,
        category: _selectedCategory,
      );

      _currentNote = newNote;
      _isEditing = true;
      debugPrint(
          '✅ ChecklistScreen: Created new checklist with ${updatedItems.length} items, final category: ${newNote.category}');

      if (mounted) {
        final settingsProvider = context.read<SettingsProvider>();
        await settingsProvider.incrementNoteCount();
      }
    }

    setState(() {
      _hasUnsavedChanges = false;
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteColor = AppTheme.getNoteColor(_selectedColor, isDark);

    return Consumer<ChecklistProvider>(
      builder: (context, checklistProvider, child) {
        final items = checklistProvider.items;
        final completedCount = checklistProvider.completedCount;
        final totalCount = checklistProvider.totalCount;
        final completionPercentage = checklistProvider.completionPercentage;

        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              // Intercept all back actions to ensure save occurs
              if (_hasUnsavedChanges || checklistProvider.items.isNotEmpty) {
                await _saveChecklist();
              }
              if (!context.mounted) return;
              context.pop();
            },
            child: Scaffold(
              backgroundColor: noteColor,
              appBar: AppBar(
                backgroundColor: noteColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black54),
                  onPressed: () async {
                    if (_hasUnsavedChanges ||
                        checklistProvider.items.isNotEmpty) {
                      await _saveChecklist();
                    }
                    if (!context.mounted) return;
                    context.pop();
                  },
                ),
                actions: [
                  IconButton(
                    icon:
                        const Icon(Icons.share_outlined, color: Colors.black54),
                    onPressed: _shareChecklist,
                  ),
                  if (_currentNote != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.black54),
                      onPressed: _deleteChecklist,
                    ),
                ],
              ),
              body: Column(
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Checklist Title',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                    ),
                  ),

                  // Progress indicator
                  if (items.isNotEmpty && completedCount > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completedCount of $totalCount completed',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '${(completionPercentage * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completionPercentage,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2196F3)),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                  // Checklist items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          // Add item button
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: GestureDetector(
                              onTap: _addNewItem,
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Add item',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // Checkbox
                              GestureDetector(
                                onTap: () => _toggleItemCompletion(index),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: item.isChecked
                                        ? const Color(0xFF2196F3)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: item.isChecked
                                          ? const Color(0xFF2196F3)
                                          : Colors.black26,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: item.isChecked
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Text field
                              Expanded(
                                child: index < _itemControllers.length
                                    ? TextField(
                                        controller: _itemControllers[index],
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter item',
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          decoration: item.isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        onChanged: (text) {
                                          _updateItemText(index, text);
                                          _onTextChanged();
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              // Delete button (always available)
                              IconButton(
                                onPressed: () => _removeItem(index),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.black26,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Bottom bar
              bottomNavigationBar: Container(
                height: 80,
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

                    // Category button
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.label_outline,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Save button
                    GestureDetector(
                      onTap: _isSaving
                          ? null
                          : () async {
                              if (!_isSaving) {
                                setState(() {
                                  _isSaving = true;
                                });
                                final navigator = Navigator.of(context);
                                await _saveChecklist();
                                if (mounted) {
                                  navigator.pop();
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
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
            ));
      },
    );
  }

  Future<void> _shareChecklist() async {
    final checklistProvider = context.read<ChecklistProvider>();
    final title = _titleController.text.trim().isEmpty
        ? 'Checklist'
        : _titleController.text.trim();
    final lines = checklistProvider.items.map((item) {
      final box = item.isChecked ? '[x]' : '[ ]';
      final text = item.text.trim().isEmpty ? 'Item' : item.text.trim();
      return '$box $text';
    }).toList();
    final content = ([title, '', ...lines]).join('\n');
    try {
      await Share.share(content, subject: title);
    } catch (_) {}
  }

  Future<void> _deleteChecklist() async {
    if (_currentNote == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checklist'),
        content: const Text(
            'Are you sure you want to delete this checklist? This action cannot be undone.'),
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

    if (confirmed == true && mounted) {
      final notesProvider = context.read<NotesProvider>();
      final checklistProvider = context.read<ChecklistProvider>();
      await checklistProvider.deleteAllChecklistItems(_currentNote!.id);
      await notesProvider.deleteNote(_currentNote!.id);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist deleted')),
        );
      }
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = ['Personal', 'Work', 'Ideas', 'Important'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
            ...categories.map((category) => ListTile(
                  title: Text(category),
                  leading: _selectedCategory == category
                      ? const Icon(Icons.check, color: Color(0xFF2196F3))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
