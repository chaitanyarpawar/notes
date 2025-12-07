import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
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
    // Ensure status/notification bar is visible
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
    final leadingBlanks = startWeekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
          ),
          IconButton(
            tooltip: 'Test Reminder',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await NotificationService.scheduleTestReminder();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test reminder scheduled in 5s')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _formatMonthYear(firstOfMonth),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    return _DayCell(number: dayNumber, isToday: isToday);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: (AdMobService.bannerAd != null)
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
            currentIndex: 1, // Highlight Calendar while on this screen
            onTap: (index) {
              if (index == 0) {
                // Go back to Notes (Home) and keep Notes highlighted there
                if (!context.mounted) return;
                context.go('/home');
              }
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
  const _DayCell({this.number, this.isToday = false});
  const _DayCell.blank()
      : number = null,
        isToday = false;
  @override
  Widget build(BuildContext context) {
    if (number == null) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFFFF4D6) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? const Color(0xFFFF9500) : Colors.black12,
        ),
      ),
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(6),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isToday ? const Color(0xFFFF9500) : Colors.black87,
        ),
      ),
    );
  }
}
