import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/note.dart';
import '../models/note_template.dart';
import '../providers/notes_provider.dart';
import '../providers/templates_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/note_options_bottom_sheet.dart';
import '../widgets/admob_banner_ad.dart';
import '../screens/settings_screen.dart';
import '../screens/templates_tab.dart';
import '../screens/calendar_screen.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = <String>{};
  int _currentTabIndex = 0; // 0: Notes, 1: Calendar, 2: Templates

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Orange header section
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFF9500),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    if (!_isSelectionMode) ...[
                      // App name
                      const Expanded(
                        child: Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Checkbox icon for selection mode
                      IconButton(
                        tooltip: 'Select notes',
                        icon: const Icon(Icons.check_box_outlined,
                            color: Colors.white, size: 26),
                        onPressed: _enterSelectionMode,
                      ),
                      // Menu icon (hamburger)
                      IconButton(
                        icon: const Icon(Icons.menu,
                            color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _exitSelectionMode,
                        tooltip: 'Cancel',
                      ),
                      Expanded(
                        child: Text(
                          '${_selectedNoteIds.length} selected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        onPressed: _selectedNoteIds.isEmpty
                            ? null
                            : _deleteSelectedNotes,
                        tooltip: 'Delete selected',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Search and filter section (only show on Notes tab)
          if (_currentTabIndex == 0)
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                        _showFilterBottomSheet();
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

          // Content based on selected tab
          Expanded(
            child: _buildCurrentTabContent(),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AdMob Banner Ad
          const AdMobBannerWidget(),
          BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
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
              BottomNavigationBarItem(
                icon: Icon(Icons.description),
                label: 'Templates',
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? Column(
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
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildNotesTab();
      case 1:
        return _buildCalendarTab();
      case 2:
        return const TemplatesTab();
      default:
        return _buildNotesTab();
    }
  }

  Widget _buildCalendarTab() {
    return const CalendarScreen();
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
          left: 8,
          right: 8,
          top: 0,
          bottom: MediaQuery.of(context).viewPadding.bottom + 80,
        ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "No notes yet" title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Create note button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _createNewNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateNoteOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
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
                  leading:
                      const Icon(Icons.checklist, color: Color(0xFFFF9500)),
                  title: const Text('Checklist'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewNote(true);
                  },
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.auto_awesome, color: Color(0xFFFF9500)),
                  title: const Text('Use Template'),
                  subtitle: const Text('Start from a template'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTemplateSelector();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTemplateSelector() {
    final templatesProvider = context.read<TemplatesProvider>();
    final allTemplates = templatesProvider.allTemplates;

    if (allTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No templates available'),
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
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Select Template',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: allTemplates.length,
                        itemBuilder: (context, index) {
                          final template = allTemplates[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFFFF9500).withOpacity(0.1),
                                child: Icon(
                                  template.templateType == TemplateType.sheet
                                      ? Icons.table_chart
                                      : (template.isBuiltIn
                                          ? Icons.auto_awesome
                                          : Icons.description),
                                  color: const Color(0xFFFF9500),
                                ),
                              ),
                              title: Text(template.title),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.pop(context);
                                // Create note with template content
                                if (template.templateType ==
                                    TemplateType.sheet) {
                                  // Navigate to note editor with sheet data
                                  context.push(
                                    '/note/new',
                                    extra: {
                                      'category': template.category,
                                      'isSheetTemplate': true,
                                      'sheetData': template.sheetData,
                                      'templateTitle': template.title,
                                    },
                                  );
                                } else {
                                  // Navigate to note editor with text template
                                  context.push(
                                    '/note/new?category=${template.category}&templateContent=${Uri.encodeComponent(template.content)}&templateTitle=${Uri.encodeComponent(template.title)}',
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final notesProvider = context.read<NotesProvider>();
        const categories = [
          'Personal',
          'Work',
          'Daily Use',
          'Finance',
          'Business',
          'Ideas',
          'Important',
        ];
        return SafeArea(
          child: SingleChildScrollView(
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
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final selected = notesProvider.selectedCategory;
                    final isSelected = selected != null &&
                        selected.toLowerCase() == cat.toLowerCase();

                    const Color selectedColor = Color(0xFFFF9500);
                    return ListTile(
                      leading: Icon(
                        Icons.label_outline,
                        color: isSelected ? selectedColor : Colors.black45,
                      ),
                      title: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? selectedColor : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: selectedColor.withValues(alpha: 0.06),
                      onTap: () {
                        Navigator.pop(context);
                        notesProvider.setSelectedCategory(cat);
                        setState(() {});
                      },
                    );
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  leading: const Icon(Icons.clear_all, color: Colors.redAccent),
                  title: const Text(
                    'Clear filters',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    notesProvider.clearAllFilters();
                    notesProvider.clearSearch();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
