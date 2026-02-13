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
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final ScrollController _dayScrollController = ScrollController();
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    // Default to current day
    final now = DateTime.now();
    final currentDay = _getFullDayName(now.weekday);
    _selectedDay = _getShortDay(currentDay);
    
    // Auto-scroll to selected day after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay();
    });
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    if (!_dayScrollController.hasClients) return;

    final index = _days.indexOf(_selectedDay);
    if (index != -1) {
      // Approximate width of each day item (padding + text + margin)
      const itemWidth = 80.0; 
      final scrollOffset = (index * itemWidth) - 20.0; // Subtract some for margin
      
      _dayScrollController.animateTo(
        scrollOffset.clamp(0.0, _dayScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
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

  String _getShortDay(String fullDay) {
    switch (fullDay.toLowerCase()) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return fullDay;
    }
  }

  List<Map<String, String>> _getClassesForSelectedDay(List<Map<String, String>> schedule) {
    final filtered = schedule.where((entry) {
      return _getShortDay(entry['day'] ?? '') == _selectedDay;
    }).toList();

    // Sort by time
    filtered.sort((a, b) {
      final timeA = a['time'] ?? '';
      final timeB = b['time'] ?? '';
      return _compareTimes(timeA, timeB);
    });

    return filtered;
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
    // Format: "10:00 AM - 10:30 AM" or "10:00 AM"
    final mainPart = timeStr.split('-').first.trim();
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.teacherUid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) {
          return Scaffold(body: const Center(child: Text('User not found')));
        }

        final userModel = UserModel.fromMap(userData);
        final dayClasses = _getClassesForSelectedDay(userModel.schedule);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text(
              'Timetable',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              _buildDaySelector(isDark),
              Expanded(
                child: dayClasses.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildTimeline(isDark, cardColor, dayClasses),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No classes scheduled for $_selectedDay',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _dayScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _days.map((day) {
            final isSelected = _selectedDay == day;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeline(bool isDark, Color cardColor, List<Map<String, String>> classes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final entry = classes[index];
        final timeStr = entry['time'] ?? 'TBD';
        
        // Extract start time for the label
        final startTime = timeStr.split('-').first.trim();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Labels
            SizedBox(
              width: 75,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startTime,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Class Cards
            Expanded(
              child: Column(
                children: [
                  _buildClassCard(entry, isDark, cardColor),
                  if (index < classes.length - 1) ...[
                    // Add break indication if there's a significant gap (optional)
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildClassCard(
    Map<String, String> entry,
    bool isDark,
    Color cardColor,
  ) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final color = colors[entry['subject'].hashCode % colors.length];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry['subject'] ?? 'Subject',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            entry['room'] ?? 'N/A',
                            color.withValues(alpha: 0.1),
                            color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(Icons.school, size: 16, color: color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Grade ${entry['classId']}-${entry['section']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry['time'] ?? '',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                              fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
