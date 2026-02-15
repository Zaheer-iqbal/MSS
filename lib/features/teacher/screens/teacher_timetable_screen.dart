import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/theme_provider.dart';

class TeacherTimetableScreen extends StatefulWidget {
  final String teacherUid;
  const TeacherTimetableScreen({super.key, required this.teacherUid});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset);
    });
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekdayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  String _getFullDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  List<Map<String, String>> _getClassesForDay(DateTime date, List<Map<String, String>> schedule) {
    final dayName = _getFullDayName(date.weekday);
    final filtered = schedule.where((entry) => entry['day'] == dayName).toList();
    
    // Sort by time
    filtered.sort((a, b) {
      final timeA = a['time'] ?? '';
      final timeB = b['time'] ?? '';
      return _compareTimes(timeA, timeB);
    });

    return filtered;
  }
  
  bool _hasClassesOnDay(DateTime date, List<Map<String, String>> schedule) {
      final dayName = _getFullDayName(date.weekday);
      return schedule.any((entry) => entry['day'] == dayName);
  }


  int _compareTimes(String timeA, String timeB) {
    try {
      final a = _parseTime(timeA);
      final b = _parseTime(timeB);
      return a.hour * 60 + a.minute - (b.hour * 60 + b.minute);
    } catch (e) {
      return 0;
    }
  }

  DateTime _parseTime(String timeStr) {
    final mainPart = timeStr.split('-').first.trim(); // "10:00 AM"
    final parts = mainPart.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';

    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF8FAFF);
    final cardColor = isDark ? const Color(0xFF1E2130) : Colors.white;
    final primaryColor = AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.teacherUid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(backgroundColor: backgroundColor, body: Center(child: Text('Error: ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) {
          return Scaffold(backgroundColor: backgroundColor, body: const Center(child: Text('User not found')));
        }

        final userModel = UserModel.fromMap(userData);
        final selectedDayClasses = _getClassesForDay(_selectedDay, userModel.schedule);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: _buildAppBar(isDark, textColor),
          body: Column(
            children: [
              _buildCalendarHeader(isDark, textColor),
              _buildWeekDaysHeader(isDark, textColor),
              _buildCalendarGrid(isDark, cardColor, primaryColor, textColor, userModel.schedule),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDay.day} ${_getMonthName(_selectedDay.month)} Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${selectedDayClasses.length} Classes',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: selectedDayClasses.isEmpty
                            ? _buildEmptyState(isDark)
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                itemCount: selectedDayClasses.length,
                                itemBuilder: (context, index) {
                                  return _buildClassCard(selectedDayClasses[index], isDark, isDark ? Colors.black26 : Colors.grey.shade50);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      title: const Text(
        'Timetable',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textColor,
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCalendarHeader(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: textColor),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: textColor),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildWeekDaysHeader(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _weekDays.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark, Color cardColor, Color primaryColor, Color textColor, List<Map<String, String>> schedule) {
    final daysInMonth = _getDaysInMonth(_focusedDay);
    final firstWeekday = _getFirstWeekdayOfMonth(_focusedDay); // 1 = Mon, 7 = Sun
    final offset = firstWeekday - 1; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0, 
        ),
        itemCount: daysInMonth + offset,
        itemBuilder: (context, index) {
          if (index < offset) return const SizedBox.shrink();
          
          final day = index - offset + 1;
          final date = DateTime(_focusedDay.year, _focusedDay.month, day);
          final isSelected = _isSameDay(date, _selectedDay);
          final isToday = _isSameDay(date, DateTime.now());
          final hasClasses = _hasClassesOnDay(date, schedule);

          return GestureDetector(
            onTap: () => _onDaySelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isSelected 
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: isSelected ? null : (isToday ? AppColors.primary.withOpacity(0.12) : Colors.transparent),
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
                border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isToday ? AppColors.primary : textColor),
                          fontSize: 16,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (hasClasses && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.redAccent]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 2)
                            ]
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enjoy your day off!',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'No classes scheduled for today',
            style: TextStyle(
              color: isDark ? Colors.white30 : Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    Map<String, String> entry,
    bool isDark,
    Color cardColor,
  ) {
    final sub = entry['subject']?.toLowerCase() ?? '';
    Color color;
    IconData icon;

    if (sub.contains('math')) {
      color = Colors.blue;
      icon = Icons.calculate;
    } else if (sub.contains('sci')) {
      color = Colors.green;
      icon = Icons.science;
    } else if (sub.contains('eng')) {
      color = Colors.purple;
      icon = Icons.translate;
    } else if (sub.contains('comp')) {
      color = Colors.teal;
      icon = Icons.computer;
    } else if (sub.contains('art')) {
      color = Colors.pink;
      icon = Icons.palette;
    } else if (sub.contains('his')) {
      color = Colors.brown;
      icon = Icons.history_edu;
    } else {
      final colors = [Colors.indigo, Colors.teal, Colors.deepOrange, Colors.blueGrey, Colors.cyan];
      color = colors[entry['subject'].hashCode % colors.length];
      icon = Icons.menu_book_rounded;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 8, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry['subject'] ?? 'Subject',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time_filled, size: 14, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  entry['time'] ?? '--:--',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTag(
                            'Class ${entry['classId']}',
                            color.withOpacity(0.1),
                            color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sec ${entry['section']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
