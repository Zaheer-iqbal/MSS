import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:mss/features/teacher/screens/enroll_student_screen.dart' show EnrollStudentScreen;
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/attendance_service.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/theme_provider.dart'; // Added this import
import '../services/teacher_api.dart';
import 'attendance_screen.dart';
import 'student_list_screen.dart';
import 'teacher_schedule_screen.dart';
import 'teacher_profile_screen.dart';
import 'manage_student_screen.dart';
import 'class_selection_screen.dart';
import '../../student/services/student_api.dart';
import '../../../core/models/student_model.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  List<Map<String, dynamic>> _classStats = [];
  List<Map<String, dynamic>> _todaySchedule = [];
  Set<String> _dismissedSessionKeys = {}; // To track deleted/dismissed red sessions
  final PageController _pageController = PageController();
  final PageController _schedulePageController = PageController(viewportFraction: 0.93);
  int _currentPage = 0;
  int _currentSchedulePage = 0;
  bool _isLoading = true;
  String? _lastFetchDate; // To reset dismissals daily
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  UserModel? _currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authUser = Provider.of<AuthService>(context).currentUser;
    if (authUser != null && (_userSubscription == null || _currentUser?.uid != authUser.uid)) {
      _currentUser = authUser;
      _setupUserSubscription(authUser.uid);
    }
  }

  void _setupUserSubscription(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final updatedUser = UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
        setState(() {
          _currentUser = updatedUser;
        });
        _fetchDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _pageController.dispose();
    _schedulePageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = _currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch Class Stats (Already implemented)
      List<Map<String, dynamic>> tempStats = [];
      for (var classInfo in user.assignedClasses) {
        final classId = classInfo['classId'] ?? '';
        final section = classInfo['section'] ?? '';
        if (classId.isNotEmpty && section.isNotEmpty) {
          String compositeId = "${classId}_$section".toLowerCase();
          final records = await _attendanceService.getClassAttendance(compositeId, DateTime.now());
          int present = 0;
          int absent = 0;
          for (var r in records) {
            if (r.status == 'present') present++;
            else if (r.status == 'absent') absent++;
          }
          final students = await FirebaseFirestore.instance
              .collection('students')
              .where('classId', isEqualTo: classId)
              .where('section', isEqualTo: section)
              .get();
          tempStats.add({
            'classId': classId,
            'section': section,
            'present': present,
            'absent': absent,
            'total': records.length,
            'totalStudents': students.docs.length,
          });
        }
      }

      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final now = DateTime.now();
      final currentDay = days[now.weekday - 1];
      final dateStr = "${now.year}-${now.month}-${now.day}";

      // Reset dismissals if it's a new day
      if (_lastFetchDate != dateStr) {
        _dismissedSessionKeys.clear();
        _lastFetchDate = dateStr;
      }
      
      final rawSchedule = user.schedule.where((e) => e['day']?.toLowerCase() == currentDay.toLowerCase()).toList();
      
      // Sort schedule by time
      rawSchedule.sort((a, b) {
        final timeA = _parseTime(a['time'] ?? '');
        final timeB = _parseTime(b['time'] ?? '');
        return timeA.compareTo(timeB);
      });

      List<Map<String, dynamic>> enrichedSchedule = [];
      for (var session in rawSchedule) {
        final classId = session['classId'] ?? '';
        final section = session['section'] ?? '';
        String compositeId = "${classId}_$section".toLowerCase();
        
        final records = await _attendanceService.getClassAttendance(compositeId, now);
        
        enrichedSchedule.add({
          ...session,
          'isMarked': records.isNotEmpty,
          'hasPassed': _isTimePassed(session['time'] ?? ''),
        });
      }

      if (mounted) {
        setState(() {
          _classStats = tempStats;
          _todaySchedule = enrichedSchedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching dashboard statistics: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isTimePassed(String timeStr) {
    if (timeStr.isEmpty) return false;
    try {
      final dt = _parseTime(timeStr);
      return DateTime.now().isAfter(dt);
    } catch (e) {
      return false;
    }
  }

  DateTime _parseTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.now();
    try {
      // Handle time ranges like "09:00 AM - 10:00 AM" by taking the start time
      String singleTimeStr = timeStr;
      if (timeStr.contains('-')) {
        singleTimeStr = timeStr.split('-')[0].trim();
      }

      // Clean and normalize input
      final cleanTime = singleTimeStr.trim().toUpperCase();
      
      // Regex to match HH:MM AM/PM or HH AM/PM or HH:MM
      // Groups: 1=Hour, 2=Minute (optional), 3=AM/PM (optional)
      final regex = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*([AP]M)?$');
      final match = regex.firstMatch(cleanTime);

      if (match == null) return DateTime.now();

      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final amPm = match.group(3);

      if (amPm != null) {
        if (amPm == 'PM' && hour != 12) hour += 12;
        if (amPm == 'AM' && hour == 12) hour = 0;
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = _currentUser ?? authService.currentUser;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, user, authService, textColor, subTextColor),
                const SizedBox(height: 24),
                if (user?.assignedClasses.isEmpty ?? true)
                  _buildNoClassesDashboard(textColor, subTextColor, isDark)
                else ...[
                  _buildAttendanceSummaryCard(isDark),
                  const SizedBox(height: 30),
                  _buildDailyScheduleCard(user, textColor, subTextColor),
                  const SizedBox(height: 30),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(context, isDark),
                  const SizedBox(height: 30),
                  _buildPendingTasksSection(textColor, subTextColor, isDark),
                ],
                const SizedBox(height: 80), 
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, AuthService authService, Color textColor, Color subTextColor) { // Added BuildContext context here
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Hello,',
              style: TextStyle(
                color: subTextColor,
                fontSize: 16,
              ),
            ),
            Text(
              user?.name ?? 'Professor',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {}, // TODO: Notifications
              icon: Icon(Icons.notifications_none, color: textColor),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TeacherProfileScreen(user: user)),
                  );
                }
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: user?.imageUrl != null ? NetworkImage(user!.imageUrl!) : null,
                child: user?.imageUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceSummaryCard(bool isDark) {
    if (_classStats.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _classStats.length,
            itemBuilder: (context, index) {
              final stats = _classStats[index];
              return _buildAttendanceSlide(stats, isDark);
            },
          ),
        ),
        if (_classStats.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _classStats.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.teacherRole : AppColors.teacherRole.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttendanceSlide(Map<String, dynamic> stats, bool isDark) {
    final total = stats['total'] ?? 0;
    final present = stats['present'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final percent = total > 0 ? ((present / total) * 100).toInt() : 0;
    final classId = stats['classId'] ?? '';
    final section = stats['section'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      strokeWidth: 8,
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: total > 0 ? present / total : 0,
                      color: AppColors.teacherRole,
                      backgroundColor: Colors.transparent,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "$percent%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Attendance: Class $classId-$section",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatBadge("$present P", Colors.blue),
                      const SizedBox(width: 4),
                      _buildStatBadge("$absent A", Colors.orange),
                      const SizedBox(width: 4),
                      _buildStatBadge("${stats['totalStudents'] ?? 0} Students", AppColors.teacherRole),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Today, ${DateTime.now().day}/${DateTime.now().month}",
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDailyScheduleCard(UserModel? user, Color textColor, Color subTextColor) {
    if (user == null) return const SizedBox.shrink();

    // Filter out sessions that are already marked or dismissed
    final visibleSessions = _todaySchedule.where((session) {
      final isMarked = session['isMarked'] ?? false;
      final key = "${session['classId']}_${session['section']}_${session['time']}";
      final isDismissed = _dismissedSessionKeys.contains(key);
      return !isMarked && !isDismissed;
    }).toList();

    if (visibleSessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: _buildEmptyScheduleView(),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = math.max(225.0, screenHeight * 0.28); // Responsive height with minimum limit

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Schedule',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (visibleSessions.length > 1)
              Text(
                '${_currentSchedulePage + 1}/${visibleSessions.length}',
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: cardHeight, // Responsive height
          child: PageView.builder(
            controller: _schedulePageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSchedulePage = index),
            itemCount: visibleSessions.length,
            itemBuilder: (context, index) {
              final session = visibleSessions[index];
              // The first session that hasn't passed is 'UP NEXT'
              final upNextSession = visibleSessions.firstWhereOrNull((s) => !(s['hasPassed'] ?? false));
              final isUpNext = session == upNextSession;
              
              return _buildScheduleSlide(session, isUpNext);
            },
          ),
        ),
        if (visibleSessions.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              visibleSessions.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentSchedulePage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentSchedulePage == index ? AppColors.teacherRole : AppColors.teacherRole.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyScheduleView() {
    return const Column(
      children: [
        Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 40),
        SizedBox(height: 16),
        Text(
          'No Class Scheduled',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'Enjoy your day!',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildScheduleSlide(Map<String, dynamic> session, bool isUpNext) {
    final hasPassed = session['hasPassed'] ?? false;
    final isRed = hasPassed; // Missed class turns red
    final sessionKey = "${session['classId']}_${session['section']}_${session['time']}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRed 
            ? [const Color(0xFFFF4B2B), const Color(0xFFFF416C)] // Red gradient
            : [const Color(0xFF2E63F6), const Color(0xFF1440C7)], // Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isRed ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildScheduleDetails(session, isUpNext),
          if (isRed)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _dismissedSessionKeys.add(sessionKey);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                tooltip: 'Dismiss missed class',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetails(Map<String, dynamic> session, bool isUpNext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isUpNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Row(
                  children: [
                    Text('⚡ ', style: TextStyle(fontSize: 10)),
                    Text('UP NEXT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Text('🕒 ', style: TextStyle(fontSize: 14)),
                  Text(
                    session['time'] ?? 'TBD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          session['subject'] ?? 'No Subject',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Grade ${session['classId']}-${session['section']}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Day: ${session['day'] ?? 'Today'} 📅',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildDarkActionCard(
          context,
          'Attendance',
          Icons.person_outline,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Attendance'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          'Results',
          Icons.description_outlined,
          Colors.green,
          // For now, let's open marks entry, user might want a specific results view later
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Exam'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          'Assignments',
          Icons.assignment_outlined,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Assignment'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          'Students',
          Icons.people_outline,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Student List'))),
          isDark
        ),
      ],
    );
  }

  Widget _buildDarkActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161822) : Colors.white, // Dark card bg vs white
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Translucent accent
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTasksSection(Color textColor, Color subTextColor, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              'Pending Tasks',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('2 New', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTaskTile('Grade Submissions', '14 pending for Algebra II', Icons.error_outline, Colors.red, textColor, subTextColor, isDark),
        const SizedBox(height: 12),
        _buildTaskTile('Attendance Missing', '9B Homeroom • Yesterday', Icons.calendar_today, Colors.blue, textColor, subTextColor, isDark),
        const SizedBox(height: 12),
        _buildTaskTile('Staff Meeting', '2nd Floor • Principal\'s Office', Icons.groups, Colors.orange, textColor, subTextColor, isDark),
      ],
    );
  }

  Widget _buildTaskTile(String title, String subtitle, IconData icon, Color color, Color textColor, Color subTextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: subTextColor, size: 14),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalytics(Color textColor, Color subTextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161822) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Performance Analytics',
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildAnalyticsRow('Attendance Rate', '94%', 0.94, Colors.blue, subTextColor),
          const SizedBox(height: 20),
          _buildAnalyticsRow('Assignments Completed', '82%', 0.82, Colors.purple, subTextColor),
          const SizedBox(height: 20),
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quiz Scores (Avg)', style: TextStyle(color: subTextColor, fontSize: 12)),
              const Text('78.5', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Simple visual bar chart placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(40, Colors.green),
              _buildBar(60, Colors.green),
              _buildBar(30, Colors.green),
              _buildBar(80, Colors.purple), // Highlight
              _buildBar(50, Colors.green),
              _buildBar(70, Colors.green),
              _buildBar(45, Colors.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, double percentage, Color color, Color subTextColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 6,
      height: height / 2, // Scale down
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNoClassesDashboard(Color textColor, Color subTextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 80, color: AppColors.teacherRole),
          const SizedBox(height: 24),
          Text(
            'Ready to Start?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t been assigned any classes yet. Once the Head Teacher assigns you classes, you\'ll see your students and schedule here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _fetchDashboardData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teacherRole,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Refresh Dashboard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

