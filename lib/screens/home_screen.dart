import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/note_options_bottom_sheet.dart';
import '../screens/settings_screen.dart';
import '../utils/constants.dart';
import '../widgets/app_brand_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  bool _isBannerAdLoaded = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = <String>{};

  final List<String> _categories = [
    'All',
    'Personal',
    'Work',
    'Ideas',
    'Important',
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final settingsProvider = context.read<SettingsProvider>();
    if (!settingsProvider.removeAds) {
      AdMobService.loadBannerAd(
        onAdLoaded: (loaded) {
          setState(() {
            _isBannerAdLoaded = loaded;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: _isSelectionMode
            ? Text(
                '${_selectedNoteIds.length} selected',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              )
            : const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: _isSelectionMode
            ? [
                if (_selectedNoteIds.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.black54,
                    onPressed: _deleteSelectedNotes,
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    color: Colors.black54,
                    onPressed: _archiveSelectedNotes,
                  ),
                ],
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  color: Colors.black54,
                  onPressed: _enterSelectionMode,
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined, size: 28),
                  color: Colors.black54,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CustomSearchBar(
              onChanged: (query) {
                final notesProvider = context.read<NotesProvider>();
                // Set search query without affecting filtered notes list
                notesProvider.searchNotes(query);
                setState(() {}); // Trigger rebuild to apply search
              },
              onClear: () {
                final notesProvider = context.read<NotesProvider>();
                notesProvider.clearSearch();
                setState(() {}); // Trigger rebuild to clear search
              },
            ),
          ),

          // Category Tabs
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF9500)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Notes List
          Expanded(
            child: _buildNotesTab(),
          ),

          // Banner Ad
          if (_isBannerAdLoaded && AdMobService.bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: AdMobService.bannerAd!.size.width.toDouble(),
              height: AdMobService.bannerAd!.size.height.toDouble(),
              margin: const EdgeInsets.only(bottom: 16),
              child: AdWidget(ad: AdMobService.bannerAd!),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _showCreateNoteOptions,
            backgroundColor: const Color(0xFFFF9500),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNotesTab() {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        // Start from provider's filtered notes (search applied), then apply category filtering
        final searchedNotes = notesProvider.notes;
        final filteredNotes = _getFilteredNotes(searchedNotes);

        return filteredNotes.isEmpty
            ? _buildEmptyState()
            : _buildNotesList(filteredNotes);
      },
    );
  }

  Widget _buildNotesList(List<Note> notes, {bool isArchived = false}) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic if needed
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return NoteCard(
              note: note,
              onTap: () => _isSelectionMode
                  ? _toggleNoteSelection(note.id)
                  : _openNote(note.id),
              onLongPress: () =>
                  _isSelectionMode ? null : _showNoteOptions(note),
              isArchived: isArchived,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedNoteIds.contains(note.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    String title = 'No notes yet',
    String subtitle = 'Start capturing your thoughts, ideas, and reminders',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand icon drawn via CustomPaint to match design
            const AppBrandIcon(size: 200),
            const SizedBox(height: 40),
            // "No notes yet" title
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Create note button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _createNewNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9500),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create your first note',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCreateNoteOptions() {
    // Use selected category from current filter - if All is selected, default to Personal
    final selectedCategory = _selectedCategoryIndex == 0
        ? 'Personal'
        : _categories[_selectedCategoryIndex];

    debugPrint(
        '🏠 HomeScreen: Showing create options for category: $selectedCategory (index: $_selectedCategoryIndex)');

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
                'Create New',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.note_add, color: Color(0xFFFF9500)),
                title: const Text('Note'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewNote(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.checklist, color: Color(0xFFFF9500)),
                title: const Text('Checklist'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewNote(true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createNewNote([bool isChecklist = false]) async {
    // Use selected category from current filter - if All is selected, default to Personal
    final selectedCategory = _selectedCategoryIndex == 0
        ? 'Personal'
        : _categories[_selectedCategoryIndex];

    debugPrint(
        '🏠 HomeScreen: Creating new ${isChecklist ? 'checklist' : 'note'} with category: $selectedCategory (filter index: $_selectedCategoryIndex)');

    final route = isChecklist
        ? '/checklist/new?category=$selectedCategory'
        : '/note/new?category=$selectedCategory';

    debugPrint('🏠 HomeScreen: Navigating to route: $route');

    // Navigate immediately for snappy UX; do not block on ads here
    if (!mounted) return;
    context.push(route);
  }

  void _openNote(String noteId) {
    final notesProvider = context.read<NotesProvider>();
    final note = notesProvider.getNoteById(noteId);

    // Check if it's a checklist (contains checkbox symbols or marked as checklist)
    if (note != null &&
        (note.content.contains('☐') ||
            note.content.contains('☑') ||
            note.content == 'Checklist')) {
      debugPrint('🏠 HomeScreen: Opening checklist note: $noteId');
      context.push('/checklist/$noteId');
    } else {
      debugPrint('🏠 HomeScreen: Opening regular note: $noteId');
      context.push('/note/$noteId');
    }
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => NoteOptionsBottomSheet(note: note),
    );
  }

  List<Note> _getFilteredNotes(List<Note> notes) {
    if (_selectedCategoryIndex == 0) {
      debugPrint(
          '🏠 HomeScreen: Showing all ${notes.length} notes (All category selected)');
      return notes; // 'All' category
    }

    final selectedCategory = _categories[_selectedCategoryIndex];
    final filteredNotes =
        notes.where((note) => note.category == selectedCategory).toList();
    debugPrint(
        '🏠 HomeScreen: Filtering for category "$selectedCategory" - Found ${filteredNotes.length}/${notes.length} notes');

    if (notes.isNotEmpty) {
      final allCategories = notes.map((n) => n.category).toSet();
      debugPrint('🏠 HomeScreen: Available categories: $allCategories');

      // Debug each note's category
      for (final note in notes) {
        debugPrint(
            '🏠 HomeScreen: Note "${note.title}" has category: "${note.category}"');
      }
    }

    return filteredNotes;
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedNoteIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    final confirmed = await _showDeleteConfirmation(
        'Delete ${_selectedNoteIds.length} notes?');
    if (confirmed == true && mounted) {
      final notesProvider = context.read<NotesProvider>();
      for (final noteId in _selectedNoteIds) {
        await notesProvider.deleteNote(noteId);
      }
      _exitSelectionMode();
    }
  }

  Future<void> _archiveSelectedNotes() async {
    final notesProvider = context.read<NotesProvider>();
    for (final noteId in _selectedNoteIds) {
      final note = notesProvider.getNoteById(noteId);
      if (note != null) {
        await notesProvider.toggleArchive(noteId);
      }
    }
    _exitSelectionMode();
  }

  Future<bool?> _showDeleteConfirmation(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(message),
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
}
