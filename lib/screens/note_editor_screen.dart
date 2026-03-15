import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/note.dart';
import '../models/sheet_template.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/color_selector.dart';
import '../utils/app_theme.dart';
import '../widgets/lined_paper.dart';
import '../controllers/formatted_text_controller.dart';
import '../widgets/formatted_text_field.dart';
import '../services/image_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/sheet_editor_widget.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final bool isChecklist;
  final bool isTemplate;
  final String category;
  final String? templateContent;
  final String? templateTitle;
  final bool isSheetTemplate;
  final SheetData? sheetData;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.isChecklist = false,
    this.isTemplate = false,
    this.category = 'Personal',
    this.templateContent,
    this.templateTitle,
    this.isSheetTemplate = false,
    this.sheetData,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final FormattedTextController _contentController = FormattedTextController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final GlobalKey _sheetRepaintKey = GlobalKey();

  Note? _currentNote;
  String? _currentNoteId; // Track the noteId to prevent duplicates
  NoteColor _selectedColor = NoteColor.yellow;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  String _selectedCategory = 'Personal';
  DateTime? _reminderTime;
  String? _lastSavedSignature;
  SheetData? _sheetData; // For sheet templates

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

        // Check if it's a sheet note
        if (_currentNote!.content.startsWith('__SHEET_DATA__:')) {
          try {
            final jsonString =
                _currentNote!.content.substring('__SHEET_DATA__:'.length);
            _sheetData = SheetData.fromJsonString(jsonString);
          } catch (e) {
            debugPrint('Error loading sheet data: $e');
          }
        } else {
          // Load from contentDelta if available, otherwise from plain content
          if (_currentNote!.contentDelta != null &&
              _currentNote!.contentDelta!.isNotEmpty) {
            _contentController.loadFromJson(_currentNote!.contentDelta!);
          } else {
            _contentController.text = _currentNote!.content;
          }
        }

        _selectedColor = _currentNote!.color;
        _selectedCategory = _currentNote!.category;
        _reminderTime = _currentNote!.reminderTime;
        debugPrint(
          '📝 NoteEditor: Loaded existing note - Category: ${_currentNote!.category}',
        );
      } else {
        debugPrint(
          '❌ NoteEditor: Could not find note with ID: ${widget.noteId}',
        );
      }
    } else {
      // New note initialization
      if (widget.isSheetTemplate && widget.sheetData != null) {
        // Initialize from sheet template
        _titleController.text = widget.templateTitle ?? 'Sheet';
        _sheetData = widget.sheetData;
        debugPrint(
          '📝 NoteEditor: Initialized from sheet template with category: $_selectedCategory',
        );
      } else if (widget.templateContent != null &&
          widget.templateTitle != null) {
        // Initialize from text template
        _titleController.text = widget.templateTitle!;
        _contentController.text = widget.templateContent!;
        debugPrint(
          '📝 NoteEditor: Initialized from template with category: $_selectedCategory',
        );
      } else if (widget.isChecklist) {
        _titleController.text = 'Checklist Title';
        _contentController.text = '☐ Item 1\n☐ Add more items';
        debugPrint(
          '📝 NoteEditor: Initialized as checklist with category: $_selectedCategory',
        );
      } else {
        debugPrint(
          '📝 NoteEditor: Initialized as new note with category: $_selectedCategory',
        );
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
    _debounceSave();
  }

  void _debounceSave() {
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

  Future<void> _saveNote({
    bool showSnackbar = true,
    bool isAutoSave = false,
  }) async {
    if (_isSaving) return; // Prevent multiple saves

    // Don't save empty notes
    final isSheetNote = _sheetData != null;
    final isEmpty = isSheetNote
        ? _titleController.text.trim().isEmpty
        : (_titleController.text.trim().isEmpty &&
            _contentController.text.trim().isEmpty);

    if (isEmpty) {
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
      '📝 NoteEditor: Starting save - isAutoSave: $isAutoSave, category: $_selectedCategory',
    );
    debugPrint('📝 NoteEditor: Title: "${_titleController.text.trim()}"');

    if (isSheetNote) {
      debugPrint(
          '📝 NoteEditor: Sheet note with total: ${_sheetData!.calculateTotal()}');
    } else {
      debugPrint(
        '📝 NoteEditor: Content length: ${_contentController.text.trim().length}',
      );
    }

    // Build a signature to avoid redundant saves when nothing changed
    String buildSignature() {
      final buf = StringBuffer()
        ..write(_titleController.text.trim())
        ..write('|');

      if (isSheetNote) {
        buf.write(_sheetData!.toJsonString());
      } else {
        buf.write(_contentController.text.trim());
      }

      buf
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
            '📝 NoteEditor: Updating existing note ID: $_currentNoteId',
          );

          final String content;
          final String contentDelta;

          if (isSheetNote) {
            content = '__SHEET_DATA__:${_sheetData!.toJsonString()}';
            contentDelta = '';
          } else {
            content = _contentController.text.trim();
            contentDelta = _contentController.toJson();
          }

          final updatedNote = noteToUpdate.copyWith(
            title: _titleController.text.trim(),
            content: content,
            contentDelta: contentDelta, // Save formatted content
            color: _selectedColor,
            category: _selectedCategory, // ✅ Category preserved in update
            reminderTime: _reminderTime,
            clearReminder: _reminderTime == null,
          );

          await notesProvider.updateNote(updatedNote);
          _currentNote = updatedNote;
          actionText = 'Note updated';
          debugPrint(
            '✅ NoteEditor: Note updated successfully with category: ${updatedNote.category}',
          );
        } else {
          debugPrint(
            '❌ NoteEditor: Could not find note to update with ID: $_currentNoteId',
          );
        }
      } else {
        // Create new note (only when noteId is null)
        debugPrint(
          '📝 NoteEditor: Creating new note with category: $_selectedCategory',
        );

        final String content;
        final String contentDelta;

        if (isSheetNote) {
          content = '__SHEET_DATA__:${_sheetData!.toJsonString()}';
          contentDelta = '';
        } else {
          content = _contentController.text.trim();
          contentDelta = _contentController.toJson();
        }

        final newNote = await notesProvider.createNote(
          title: _titleController.text.trim(),
          content: content,
          contentDelta: contentDelta, // Save formatted content
          color: _selectedColor,
          category: _selectedCategory, // ✅ Category included in create
          reminderTime: _reminderTime,
        );

        // Set the noteId and current note so all subsequent saves will update
        _currentNoteId = newNote.id;
        _currentNote = newNote;
        actionText = 'Note created';
        debugPrint(
          '✅ NoteEditor: Note created successfully - ID: ${newNote.id}, Category: ${newNote.category}',
        );

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
    // If it's a sheet, show export options
    if (_sheetData != null) {
      _showSheetExportOptions();
      return;
    }

    // Regular note sharing
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final subject = title.isEmpty ? 'Note' : title;
    final text = content.isEmpty ? subject : '$subject\n\n$content';
    try {
      await Share.share(text, subject: subject);
    } catch (_) {}
  }

  Future<void> _showSheetExportOptions() async {
    if (_sheetData == null) return;

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
              'Export Sheet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate and share PDF document'),
              onTap: () {
                Navigator.pop(context);
                _exportSheetAsPdf();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.print, color: Colors.blue.shade700),
              ),
              title: const Text('Preview & Print'),
              subtitle: const Text('Open print preview'),
              onTap: () {
                Navigator.pop(context);
                _previewSheetPdf();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: Colors.purple.shade700),
              ),
              title: const Text('Share as Image'),
              subtitle: const Text('Capture and share as picture'),
              onTap: () {
                Navigator.pop(context);
                _shareSheetAsImage();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.text_snippet, color: Colors.green.shade700),
              ),
              title: const Text('Share as Text'),
              subtitle: const Text('Share plain text format'),
              onTap: () {
                Navigator.pop(context);
                _shareSheetAsText();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSheetAsPdf() async {
    if (_sheetData == null) return;

    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      await PdfExportService.exportAndSharePdf(
        sheetData: _sheetData!,
        title: _titleController.text.isEmpty
            ? 'Sheet Export'
            : _titleController.text,
        subtitle: _selectedCategory,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('PDF generated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _previewSheetPdf() async {
    if (_sheetData == null) return;

    try {
      await PdfExportService.previewAndPrintPdf(
        sheetData: _sheetData!,
        title: _titleController.text.isEmpty
            ? 'Sheet Export'
            : _titleController.text,
        subtitle: _selectedCategory,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareSheetAsText() async {
    if (_sheetData == null) return;

    try {
      final title =
          _titleController.text.isEmpty ? 'Sheet' : _titleController.text;
      final buffer = StringBuffer();

      buffer.writeln(title);
      buffer.writeln('Category: $_selectedCategory');
      buffer.writeln(
          'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
      buffer.writeln('=' * 40);
      buffer.writeln();

      // Column headers
      buffer.writeln(_sheetData!.columns.map((c) => c.name).join(' | '));
      buffer.writeln('-' * 40);

      // Rows
      for (var row in _sheetData!.rows) {
        final values =
            _sheetData!.columns.map((col) => row.cells[col.id] ?? '').toList();
        buffer.writeln(values.join(' | '));
      }

      // Total
      if (_sheetData!.hasTotal) {
        buffer.writeln('-' * 40);
        buffer.writeln(
            '${_sheetData!.totalLabel ?? 'Total'}: ${_sheetData!.currencySymbol ?? '₹'}${_sheetData!.calculateTotal().toStringAsFixed(2)}');
      }

      await Share.share(buffer.toString(), subject: title);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareSheetAsImage() async {
    if (_sheetData == null) return;

    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Capturing image...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a bit for the snackbar to render
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the widget as image
      final boundary = _sheetRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture sheet. Please try again.');
      }

      // Capture at higher resolution for better quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/sheet_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // Share the image
      final title =
          _titleController.text.isEmpty ? 'Sheet' : _titleController.text;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shared from PebbleNote',
        subject: title,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Image captured successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
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

          // Reminder and Category row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              children: [
                // Reminder chip (left)
                GestureDetector(
                  onTap: _pickReminder,
                  child: Container(
                    height: 36,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alarm,
                          color: Color(0xFFFF9500),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Reminder',
                          style: TextStyle(
                            color: Color(0xFFFF9500),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Category chip (right)
                GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Container(
                    height: 36,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.label,
                          color: Color(0xFFFF9500),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCategory,
                          style: const TextStyle(
                            color: Color(0xFFFF9500),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active reminder display (below buttons)
          if (_reminderTime != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatReminder(_reminderTime!),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearReminder,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content field - main area with rich text formatting or sheet editor
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _sheetData != null
                  ? RepaintBoundary(
                      key: _sheetRepaintKey,
                      child: Container(
                        color: Colors.white,
                        child: SheetEditorWidget(
                          sheetData: _sheetData!,
                          onChanged: (updatedSheetData) {
                            setState(() {
                              _sheetData = updatedSheetData;
                              _hasUnsavedChanges = true;
                            });
                            _debounceSave();
                          },
                          readOnly: false,
                        ),
                      ),
                    )
                  : LinedPaper(
                      padding: EdgeInsets.zero,
                      lineSpacing: 28.0, // Good spacing for writing
                      child: FormattedTextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        hintText: widget.isChecklist
                            ? '☐ Add items...'
                            : 'Start typing...',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.black45,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          height:
                              1.75, // Adjusted to align with 28px line spacing
                          color: Colors.black87,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        onImageInserted: (imagePath) {
                          setState(() {
                            _hasUnsavedChanges = true;
                          });
                          // Image stored in formatting data
                        },
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
              // Color picker button with selected color indicator
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getNoteColorValue(_selectedColor),
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: _getNoteColorValue(_selectedColor),
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

              // Save button - now always visible and functional
              GestureDetector(
                onTap: _isSaving ? null : _handleManualSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  // Helper method to get vibrant color for border/icon highlighting
  Color _getNoteColorValue(NoteColor noteColor) {
    switch (noteColor) {
      case NoteColor.yellow:
        return const Color(0xFFFBC02D);
      case NoteColor.blue:
        return const Color(0xFF2196F3);
      case NoteColor.purple:
        return const Color(0xFF9C27B0);
      case NoteColor.pink:
        return const Color(0xFFE91E63);
      case NoteColor.green:
        return const Color(0xFF4CAF50);
      case NoteColor.orange:
        return const Color(0xFFFF9500);
    }
  }

  // Keyboard toolbar action handlers
  void _showTextFormatOptions() {
    // Check if text is selected
    final currentSelection = _contentController.selection;

    if (currentSelection.start == currentSelection.end) {
      // No text selected, show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select text first to apply formatting'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Get current style dynamically
          final style = _contentController.getCurrentStyle();

          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Font',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                        _contentFocusNode.requestFocus();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Style buttons row
                Row(
                  children: [
                    _formatButton(
                      icon: Icons.format_bold,
                      isActive: style.bold,
                      onTap: () {
                        _contentController.selection = currentSelection;
                        _contentController.toggleBold();
                        setModalState(() {});
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _formatButton(
                      icon: Icons.format_italic,
                      isActive: style.italic,
                      onTap: () {
                        _contentController.selection = currentSelection;
                        _contentController.toggleItalic();
                        setModalState(() {});
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _formatButton(
                      icon: Icons.format_underline,
                      isActive: style.underline,
                      onTap: () {
                        _contentController.selection = currentSelection;
                        _contentController.toggleUnderline();
                        setModalState(() {});
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _formatButton(
                      icon: Icons.format_strikethrough,
                      isActive: false,
                      onTap: () {
                        // Strikethrough coming soon
                      },
                    ),
                    const Spacer(),
                    // Font size controls
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('Tt',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // Decrease font size
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Text('16',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // Increase font size
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Text color picker
                Row(
                  children: [
                    const Text('A',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _colorButton(Colors.transparent,
                                isActive: style.color == Colors.black ||
                                    style.color == null,
                                hasStroke: true, onTap: () {
                              _contentController.selection = currentSelection;
                              _contentController.setColor(Colors.black);
                              setModalState(() {});
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            }),
                            _colorButton(Colors.red[300]!,
                                isActive: style.color == Colors.red[300],
                                onTap: () {
                              _contentController.selection = currentSelection;
                              _contentController.setColor(Colors.red[300]!);
                              setModalState(() {});
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            }),
                            _colorButton(Colors.yellow[600]!,
                                isActive: style.color == Colors.yellow[600],
                                onTap: () {
                              _contentController.selection = currentSelection;
                              _contentController.setColor(Colors.yellow[600]!);
                              setModalState(() {});
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            }),
                            _colorButton(Colors.yellow[300]!,
                                isActive: style.color == Colors.yellow[300],
                                onTap: () {
                              _contentController.selection = currentSelection;
                              _contentController.setColor(Colors.yellow[300]!);
                              setModalState(() {});
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            }),
                            _colorButton(Colors.cyan[200]!,
                                isActive: style.color == Colors.cyan[200],
                                onTap: () {
                              _contentController.selection = currentSelection;
                              _contentController.setColor(Colors.cyan[200]!);
                              setModalState(() {});
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            }),
                            _colorButton(Colors.purple[200]!,
                                isActive: style.color == Colors.purple[200],
                                onTap: () {
                              _contentController.selection = currentSelection;
                              _contentController.setColor(Colors.purple[200]!);
                              setModalState(() {});
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            }),
                            _colorButton(null, isGradient: true, onTap: () {
                              // Color picker
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Background color picker
                Row(
                  children: [
                    const Icon(Icons.text_format, size: 18),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _colorButton(Colors.grey[800]!, onTap: () {}),
                            _colorButton(Colors.blue[800]!, onTap: () {}),
                            _colorButton(Colors.red[700]!, onTap: () {}),
                            _colorButton(Colors.orange[700]!, onTap: () {}),
                            _colorButton(Colors.green[700]!, onTap: () {}),
                            _colorButton(Colors.cyan[600]!, onTap: () {}),
                            _colorButton(null, isGradient: true, onTap: () {}),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Font family picker
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _fontFamilyButton('PebbleNote', 'Default',
                          (style.fontFamily ?? 'Roboto') == 'Roboto',
                          onTap: () {
                        _contentController.selection = currentSelection;
                        _contentController.setFontFamily('Roboto');
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                      }),
                      _fontFamilyButton('PebbleNote', 'Cursive',
                          (style.fontFamily ?? '') == 'DancingScript',
                          onTap: () {
                        _contentController.selection = currentSelection;
                        _contentController.setFontFamily('DancingScript');
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                      }, fontFamily: 'DancingScript'),
                      _fontFamilyButton('PebbleNote', 'Monospace',
                          (style.fontFamily ?? '') == 'CourierPrime',
                          onTap: () {
                        _contentController.selection = currentSelection;
                        _contentController.setFontFamily('CourierPrime');
                        setState(() {
                          _hasUnsavedChanges = true;
                        });
                      }, fontFamily: 'Courier'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _formatButton(
      {required IconData icon,
      required bool isActive,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 20, color: isActive ? Colors.blue[700] : Colors.black87),
      ),
    );
  }

  Widget _colorButton(Color? color,
      {bool isActive = false,
      bool hasStroke = false,
      bool isGradient = false,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isGradient ? null : color,
          gradient: isGradient
              ? const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple
                  ],
                )
              : null,
          border:
              hasStroke ? Border.all(color: Colors.grey[400]!, width: 2) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  const BoxShadow(
                      color: Colors.blue, blurRadius: 4, spreadRadius: 1),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _fontFamilyButton(String text, String label, bool isActive,
      {String? fontFamily, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[100] : Colors.grey[100],
          border:
              isActive ? Border.all(color: Colors.blue[700]!, width: 2) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontFamily: fontFamily,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showBackgroundImagePicker() {
    final backgrounds = [
      {'color': const Color(0xFFFFF9C4), 'label': 'Yellow'},
      {'color': const Color(0xFFFFE0B2), 'label': 'Orange'},
      {'color': const Color(0xFFC8E6C9), 'label': 'Green'},
      {'color': const Color(0xFFFFCDD2), 'label': 'Pink'},
      {'color': const Color(0xFFE1BEE7), 'label': 'Purple'},
      {'color': const Color(0xFFB3E5FC), 'label': 'Blue'},
    ];

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
              'Background Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: backgrounds.length,
              itemBuilder: (context, index) {
                final bg = backgrounds[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // Apply background (would need to add this to note model)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Background theme: ${bg['label']}')),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _insertCheckbox() {
    final currentText = _contentController.text;
    final selection = _contentController.selection;

    // Insert checkbox at cursor position
    final newText =
        '${currentText.substring(0, selection.start)}☐ ${currentText.substring(selection.start)}';

    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + 2,
    );
  }

  void _showImagePickerOptions() {
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
              'Insert Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ImageService().pickImageFromCamera();
                if (imagePath != null) {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                  // Image path stored, can be displayed later
                  final currentText = _contentController.text;
                  final selection = _contentController.selection;
                  final newText =
                      '${currentText.substring(0, selection.start)}[Image: $imagePath]${currentText.substring(selection.start)}';
                  _contentController.text = newText;
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ImageService().pickImageFromGallery();
                if (imagePath != null) {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                  final currentText = _contentController.text;
                  final selection = _contentController.selection;
                  final newText =
                      '${currentText.substring(0, selection.start)}[Image: $imagePath]${currentText.substring(selection.start)}';
                  _contentController.text = newText;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = ['😊', '😂', '❤️', '👍', '🎉', '⭐', '✨', '🔥', '💡', '✅'];

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
              'Insert Emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((emoji) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    final currentText = _contentController.text;
                    final selection = _contentController.selection;
                    final newText = currentText.substring(0, selection.start) +
                        emoji +
                        currentText.substring(selection.start);
                    _contentController.text = newText;
                    _contentController.selection = TextSelection.collapsed(
                      offset: selection.start + emoji.length,
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _insertAtCursor(String text) {
    final currentText = _contentController.text;
    final selection = _contentController.selection;
    final newText = currentText.substring(0, selection.start) +
        text +
        currentText.substring(selection.start);
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }

  void _showCategoryPicker() {
    final categories = [
      'Personal',
      'Work',
      'Daily Use',
      'Finance',
      'Business',
      'Ideas',
      'Important'
    ];

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: categories.map((category) {
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
                    }).toList(),
                  ),
                ),
              ),
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
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(d.year, d.month, d.day);

    String two(int n) => n.toString().padLeft(2, '0');
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final time = '${two(hour)}:${two(d.minute)} $ampm';

    if (reminderDay == today) {
      return 'Today $time';
    } else if (reminderDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow $time';
    } else {
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
      final diff = reminderDay.difference(today).inDays;

      // Within a week - show day name
      if (diff > 0 && diff < 7) {
        return '$wd $time';
      }
      // Further out - show date
      return '${d.day} $mn $time';
    }
  }

  Future<void> _clearReminder() async {
    setState(() {
      _reminderTime = null;
      _hasUnsavedChanges = true;
    });
    await _autoSave();
  }
}
