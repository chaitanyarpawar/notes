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
  bool _isBannerAdLoaded = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = <String>{};
  int _currentTabIndex = 0; // 0: Notes, 1: Calendar

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
        title: Row(
          children: [
            if (!_isSelectionMode) ...[
              const Expanded(
                child: Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Select notes',
                    icon: const Icon(Icons.check_box_outlined),
                    color: const Color(0xFFFF9500),
                    onPressed: _enterSelectionMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle_outlined, size: 26),
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
            ] else ...[
              Expanded(
                child: Text(
                  '${_selectedNoteIds.length} selected',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                onPressed:
                    _selectedNoteIds.isEmpty ? null : _deleteSelectedNotes,
                tooltip: 'Delete selected',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: Colors.black54,
                onPressed: _exitSelectionMode,
                tooltip: 'Cancel',
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      onChanged: (query) {
                        final notesProvider = context.read<NotesProvider>();
                        notesProvider.searchNotes(query);
                        setState(() {});
                      },
                      onClear: () {
                        final notesProvider = context.read<NotesProvider>();
                        notesProvider.clearSearch();
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Unified filters in one place
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) {
                            final notesProvider = context.read<NotesProvider>();
                            const categories = [
                              'Personal',
                              'Work',
                              'Ideas',
                              'Important',
                            ];
                            return SizedBox(
                              height: 360,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Category',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final cat = categories[index];
                                      final selected =
                                          notesProvider.selectedCategory;
                                      final isSelected = selected != null &&
                                          selected.toLowerCase() ==
                                              cat.toLowerCase();

                                      const Color selectedColor =
                                          Color(0xFFFF9500);
                                      return ListTile(
                                        leading: Icon(
                                          Icons.label_outline,
                                          color: isSelected
                                              ? selectedColor
                                              : Colors.black45,
                                        ),
                                        title: Text(
                                          cat,
                                          style: TextStyle(
                                            color: isSelected
                                                ? selectedColor
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedTileColor: selectedColor
                                            .withValues(alpha: 0.06),
                                        onTap: () {
                                          Navigator.pop(context);
                                          notesProvider
                                              .setSelectedCategory(cat);
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                  const Divider(height: 16),
                                  ListTile(
                                    leading: const Icon(Icons.clear_all),
                                    title: const Text('Clear filters'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      notesProvider.clearAllFilters();
                                      notesProvider.clearSearch();
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notes List
            Expanded(
              child: _buildNotesTab(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show test ads above the navigation bar
          SizedBox(
            height: 48,
            child: (_isBannerAdLoaded && AdMobService.bannerAd != null)
                ? Center(child: AdWidget(ad: AdMobService.bannerAd!))
                : Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: const Text(
                      'space for ads',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
          ),
          BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
              // Keep Notes tab highlighted; open Calendar as a separate route
              if (index == 1) {
                // Immediately ensure Notes remains highlighted
                if (_currentTabIndex != 0) {
                  setState(() {
                    _currentTabIndex = 0;
                  });
                }
                try {
                  GoRouter.of(context).push('/calendar');
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calendar view coming soon')),
                  );
                }
                // Do not change _currentTabIndex so Notes remains highlighted
                return;
              }
              setState(() {
                _currentTabIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.note),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
            ],
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
        final filteredNotes = notesProvider.notes;

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
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 0,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
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
    // Default category handled in _createNewNote

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
    // Default category to Personal
    const selectedCategory = 'Personal';

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

  // Category filters removed; rely on search and unified Filter button

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

  // _archiveSelectedNotes removed (unused)

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
