import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../models/sheet_template.dart';
// Removed intl dependency; using local month names

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _shownMonth; // normalized to first day of month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _shownMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _shownMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstOfMonth = _shownMonth;
    final daysInMonth =
        DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday; // 1=Mon ... 7=Sun
    final leadingBlanks = startWeekday - 1; // Mon=0, Tue=1, ..., Sun=6
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    // Get notes from provider and group by date
    final notesProvider = context.watch<NotesProvider>();
    final allNotes = notesProvider.allNotes.where((note) => !note.isArchived).toList();
    
    // Create a map of date to notes count for the current month
    final Map<int, List<Note>> notesByDay = {};
    for (var note in allNotes) {
      if (note.createdAt.year == firstOfMonth.year &&
          note.createdAt.month == firstOfMonth.month) {
        final day = note.createdAt.day;
        notesByDay.putIfAbsent(day, () => []).add(note);
      }
    }

    return Column(
      children: [
        // Month navigation header with today button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
                color: const Color(0xFFFF9500),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _formatMonthYear(firstOfMonth),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                color: const Color(0xFFFF9500),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _goToToday,
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Today'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9500),
                  side: const BorderSide(color: Color(0xFFFF9500)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        // Weekday labels
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
              _WeekdayLabel('Sun'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Calendar grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: rows * 7,
              itemBuilder: (context, index) {
                final dayNumber = index - leadingBlanks + 1;
                if (index < leadingBlanks ||
                    dayNumber < 1 ||
                    dayNumber > daysInMonth) {
                  return const _DayCell.blank();
                }
                final isToday = now.year == firstOfMonth.year &&
                    now.month == firstOfMonth.month &&
                    dayNumber == now.day;
                final notesForDay = notesByDay[dayNumber] ?? [];
                final selectedDate = DateTime(firstOfMonth.year, firstOfMonth.month, dayNumber);
                return _DayCell(
                  number: dayNumber, 
                  isToday: isToday,
                  noteCount: notesForDay.length,
                  onTap: notesForDay.isNotEmpty 
                    ? () => _showNotesForDate(context, selectedDate, notesForDay)
                    : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final monthName = months[dt.month - 1];
    return '$monthName ${dt.year}';
  }

  void _showNotesForDate(BuildContext context, DateTime date, List<Note> notes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Text(
                      '${_formatDate(date)} - ${notes.length} ${notes.length == 1 ? 'Note' : 'Notes'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/note/${note.id}');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title.isEmpty ? 'Untitled' : note.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (note.isPinned)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.push_pin,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                ],
                              ),
                              if (note.content.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildNoteContent(note),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(note.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteContent(Note note) {
    // Check if this is a sheet template note
    if (note.content.startsWith('__SHEET_DATA__:')) {
      try {
        final jsonString = note.content.substring('__SHEET_DATA__:'.length);
        final sheetData = SheetData.fromJsonString(jsonString);
        
        // Show table preview with icon and summary
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.table_chart,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sheetData.columns.map((col) => col.name).join(' • '),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${sheetData.rows.length} ${sheetData.rows.length == 1 ? 'row' : 'rows'}${sheetData.hasTotal ? ' • Total: ${sheetData.currencySymbol ?? '₹'}${sheetData.calculateTotal().toStringAsFixed(2)}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      } catch (e) {
        // If parsing fails, show generic sheet indicator
        return Row(
          children: [
            Icon(
              Icons.table_chart,
              size: 16,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 6),
            Text(
              'Sheet Template',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      }
    }
    
    // Regular note content
    return Text(
      note.content.length > 100
          ? '${note.content.substring(0, 100)}...'
          : note.content,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int? number;
  final bool isToday;
  final int noteCount;
  final VoidCallback? onTap;
  
  const _DayCell({
    this.number, 
    this.isToday = false,
    this.noteCount = 0,
    this.onTap,
  });
  
  const _DayCell.blank()
      : number = null,
        isToday = false,
        noteCount = 0,
        onTap = null;
  
  @override
  Widget build(BuildContext context) {
    if (number == null) {
      return const SizedBox.shrink();
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFFFF4D6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? const Color(0xFFFF9500) : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isToday ? const Color(0xFFFF9500) : Colors.black87,
                ),
              ),
            ),
            if (noteCount > 0) ...[
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  noteCount > 9 ? '9+' : '$noteCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
