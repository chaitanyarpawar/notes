import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';

class NotesProvider extends ChangeNotifier {
  final Box<Note> _notesBox = Hive.box<Note>(AppConstants.notesBox);
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  Timer? _searchDebouncer;
  bool _showPinnedOnly = false;
  bool _showArchived = false;
  bool _showScreenshotsOnly = false;
  String? _selectedCategory; // null means all categories

  NotesProvider() {
    _loadNotes();
  }

  // Getters
  List<Note> get notes => _filteredNotes;
  List<Note> get allNotes => _notes;
  List<Note> get pinnedNotes =>
      _notes.where((note) => note.isPinned && !note.isArchived).toList();
  List<Note> get archivedNotes =>
      _notes.where((note) => note.isArchived).toList();
  String get searchQuery => _searchQuery;
  int get notesCount => _notes.where((note) => !note.isArchived).length;
  bool get showPinnedOnly => _showPinnedOnly;
  bool get showArchived => _showArchived;
  bool get showScreenshotsOnly => _showScreenshotsOnly;
  String? get selectedCategory => _selectedCategory;

  void _loadNotes() {
    _notes = _notesBox.values.toList();
    debugPrint('💾 NotesProvider: Loaded ${_notes.length} notes from storage');
    if (_notes.isNotEmpty) {
      final categories = _notes.map((n) => n.category).toSet();
      debugPrint('💾 NotesProvider: Categories in storage: $categories');
    }
    _sortNotes();
    _applyFilters();
    notifyListeners();
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      // Pinned notes first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Then by updated date (newest first)
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  void _applyFilters() {
    Iterable<Note> source = _notes;
    // Archived view toggle: if true, show only archived; else exclude archived
    if (_showArchived) {
      source = source.where((n) => n.isArchived);
    } else {
      source = source.where((n) => !n.isArchived);
    }
    // Pinned-only toggle
    if (_showPinnedOnly) {
      source = source.where((n) => n.isPinned);
    }
    // Screenshots-only (by category name)
    if (_showScreenshotsOnly) {
      source = source.where(
        (n) => (n.category).toLowerCase() == 'screenshots',
      );
    }
    // Specific category filter (overrides screenshots-only if set)
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      final cat = _selectedCategory!.toLowerCase();
      source = source.where((n) => n.category.toLowerCase() == cat);
    }
    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      source = source.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q));
    }
    _filteredNotes = source.toList();
  }

  Future<Note> createNote({
    String title = '',
    String content = '',
    NoteColor color = NoteColor.yellow,
    String category = 'Personal',
    DateTime? reminderTime,
  }) async {
    final now = DateTime.now();
    var note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      color: color,
      createdAt: now,
      updatedAt: now,
      category: category,
      reminderTime: reminderTime,
    );

    debugPrint(
        '💾 NotesProvider: Creating note - ID: ${note.id}, Category: ${note.category}, Title: "${note.title}"');
    debugPrint(
        '💾 NotesProvider: Category passed: "$category", Note category: "${note.category}"');
    try {
      // If reminder is set, compute and store notificationId before saving
      if (note.reminderTime != null &&
          note.reminderTime!.isAfter(DateTime.now())) {
        final nid = NotificationService.computeNotificationId(note.id);
        note = note.copyWith(notificationId: nid);
      }
      await _notesBox.put(note.id, note);
    } catch (e, st) {
      debugPrint('❌ NotesProvider: Failed to write new note: $e');
      debugPrint('❌ NotesProvider: Stack: $st');
      rethrow;
    }
    _loadNotes();
    // Schedule reminder if set in the future
    if (note.reminderTime != null &&
        note.reminderTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleReminder(note);
    }
    debugPrint(
        '✅ NotesProvider: Note created and stored successfully with category: ${note.category}');
    return note;
  }

  Future<void> updateNote(Note note) async {
    var updatedNote = note.copyWith(updatedAt: DateTime.now());
    debugPrint(
        '💾 NotesProvider: Updating note - ID: ${note.id}, Category: ${updatedNote.category}, Title: "${updatedNote.title}"');
    try {
      // Manage notificationId storage based on reminder state
      if (updatedNote.reminderTime != null &&
          updatedNote.reminderTime!.isAfter(DateTime.now())) {
        final nid = NotificationService.computeNotificationId(updatedNote.id);
        updatedNote = updatedNote.copyWith(notificationId: nid);
      } else {
        updatedNote = updatedNote.copyWith(notificationId: null);
      }
      await _notesBox.put(note.id, updatedNote);
    } catch (e, st) {
      debugPrint('❌ NotesProvider: Failed to update note ${note.id}: $e');
      debugPrint('❌ NotesProvider: Stack: $st');
      rethrow;
    }
    _loadNotes();
    if (updatedNote.reminderTime != null &&
        updatedNote.reminderTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleReminder(updatedNote);
    } else {
      // Reminder cleared or in the past: cancel any existing scheduled notification
      await NotificationService.cancelReminderByNoteId(updatedNote.id);
    }
    debugPrint('✅ NotesProvider: Note updated successfully');
  }

  Future<void> deleteNote(String noteId) async {
    // Cancel any scheduled reminder for this note before deleting
    try {
      await NotificationService.cancelReminderByNoteId(noteId);
    } catch (_) {}
    try {
      await _notesBox.delete(noteId);
    } catch (e, st) {
      debugPrint('❌ NotesProvider: Failed to delete note $noteId: $e');
      debugPrint('❌ NotesProvider: Stack: $st');
      rethrow;
    }
    _loadNotes();
  }

  Future<void> togglePin(String noteId) async {
    final note = _notesBox.get(noteId);
    if (note != null) {
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await _notesBox.put(noteId, updatedNote);
      _loadNotes();
    }
  }

  Future<void> toggleArchive(String noteId) async {
    final note = _notesBox.get(noteId);
    if (note != null) {
      final updatedNote = note.copyWith(
        isArchived: !note.isArchived,
        isPinned:
            note.isArchived ? note.isPinned : false, // Unpin when archiving
        updatedAt: DateTime.now(),
      );
      await _notesBox.put(noteId, updatedNote);
      _loadNotes();
    }
  }

  void searchNotes(String query) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _searchDebouncer?.cancel();
    _applyFilters();
    notifyListeners();
  }

  void setShowPinnedOnly(bool value) {
    _showPinnedOnly = value;
    _applyFilters();
    notifyListeners();
  }

  void setShowArchived(bool value) {
    _showArchived = value;
    _applyFilters();
    notifyListeners();
  }

  void setShowScreenshotsOnly(bool value) {
    _showScreenshotsOnly = value;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    // If a specific category is chosen, disable screenshots-only
    if (category != null && category.isNotEmpty) {
      _showScreenshotsOnly = false;
    }
    _applyFilters();
    notifyListeners();
  }

  void clearAllFilters() {
    _showPinnedOnly = false;
    _showArchived = false;
    _showScreenshotsOnly = false;
    _selectedCategory = null;
    _applyFilters();
    notifyListeners();
  }

  Note? getNoteById(String id) {
    return _notesBox.get(id);
  }

  Future<Note?> duplicateNote(String noteId) async {
    final note = _notesBox.get(noteId);
    if (note != null) {
      // Create the duplicated note preserving category and reminder
      final newNote = await createNote(
        title: '${note.title} (Copy)',
        content: note.content,
        color: note.color,
        category: note.category,
        reminderTime: note.reminderTime,
      );
      return newNote;
    }
    return null;
  }

  Future<void> clearAllNotes() async {
    await _notesBox.clear();
    _loadNotes();
  }

  /// Replace all local notes from a backup JSON payload.
  /// Expects a list of maps with keys: id, title, content, category, createdAt, updatedAt, color(optional).
  Future<void> replaceAllFromBackup(
      List<Map<String, dynamic>> notesMaps) async {
    await _notesBox.clear();
    for (final m in notesMaps) {
      final created = _parseDate(m['createdAt']);
      final updated = _parseDate(m['updatedAt']);
      final colorName = m['color'];
      final color = _parseColor(colorName) ?? NoteColor.yellow;
      final note = Note(
        id: m['id'] as String,
        title: (m['title'] ?? '') as String,
        content: (m['content'] ?? '') as String,
        color: color,
        createdAt: created ?? DateTime.now(),
        updatedAt: updated ?? DateTime.now(),
        category: (m['category'] ?? 'Personal') as String,
        isPinned: (m['isPinned'] ?? false) as bool? ?? false,
        isArchived: (m['isArchived'] ?? false) as bool? ?? false,
      );
      await _notesBox.put(note.id, note);
    }
    _loadNotes();
  }

  DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  NoteColor? _parseColor(dynamic v) {
    if (v is String) {
      for (final c in NoteColor.values) {
        if (c.name == v) return c;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    super.dispose();
  }
}
