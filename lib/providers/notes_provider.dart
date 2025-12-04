import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../utils/constants.dart';

class NotesProvider extends ChangeNotifier {
  final Box<Note> _notesBox = Hive.box<Note>(AppConstants.notesBox);
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  Timer? _searchDebouncer;

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
    if (_searchQuery.isEmpty) {
      _filteredNotes = _notes.where((note) => !note.isArchived).toList();
    } else {
      _filteredNotes = _notes.where((note) {
        return !note.isArchived &&
            (note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                note.content.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ));
      }).toList();
    }
  }

  Future<Note> createNote({
    String title = '',
    String content = '',
    NoteColor color = NoteColor.yellow,
    String category = 'Personal',
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      color: color,
      createdAt: now,
      updatedAt: now,
      category: category,
    );

    debugPrint(
        '💾 NotesProvider: Creating note - ID: ${note.id}, Category: ${note.category}, Title: "${note.title}"');
    debugPrint(
        '💾 NotesProvider: Category passed: "$category", Note category: "${note.category}"');
    await _notesBox.put(note.id, note);
    _loadNotes();
    debugPrint(
        '✅ NotesProvider: Note created and stored successfully with category: ${note.category}');
    return note;
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    debugPrint(
        '💾 NotesProvider: Updating note - ID: ${note.id}, Category: ${updatedNote.category}, Title: "${updatedNote.title}"');
    await _notesBox.put(note.id, updatedNote);
    _loadNotes();
    debugPrint('✅ NotesProvider: Note updated successfully');
  }

  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
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

  Note? getNoteById(String id) {
    return _notesBox.get(id);
  }

  Future<void> duplicateNote(String noteId) async {
    final note = _notesBox.get(noteId);
    if (note != null) {
      await createNote(
        title: '${note.title} (Copy)',
        content: note.content,
        color: note.color,
      );
    }
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
