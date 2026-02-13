import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/theme_provider.dart'; // Added this import
import '../../../../core/models/teacher_attendance_model.dart';
import '../../../../core/services/teacher_attendance_service.dart';
import '../../../../core/services/teacher_dismissal_service.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'teacher_profile_screen.dart';
import 'class_selection_screen.dart';
import 'teacher_timetable_screen.dart';
import '../../school/services/school_api.dart';
import '../../../core/models/school_event_model.dart';
import '../../../core/services/notification_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final TeacherAttendanceService _teacherAttendanceService = TeacherAttendanceService();
  final TeacherDismissalService _dismissalService = TeacherDismissalService();
  List<Map<String, dynamic>> _classStats = [];
  List<Map<String, dynamic>> _todaySchedule = [];
  final Set<String> _dismissedSessionKeys = {}; // To track deleted/dismissed red sessions
  final PageController _pageController = PageController();
  final PageController _schedulePageController = PageController();
  int _currentPage = 0;
  int _currentSchedulePage = 0;
  bool _isLoading = true; 
  String? _lastFetchDate; // To reset dismissals daily
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<TeacherAttendanceModel?>? _attendanceSubscription;
  Timer? _autoSlideTimer;

  UserModel? _currentUser;
  bool _isAttendanceMarked = false;
  String _attendanceStatus = '';

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
        _setupAttendanceSubscription(uid);
      }
    });
  }

  void _setupAttendanceSubscription(String uid) {
    _attendanceSubscription?.cancel();
    final today = DateTime.now();
    _attendanceSubscription = _teacherAttendanceService
        .getAttendanceStreamForDate(uid, DateTime(today.year, today.month, today.day))
        .listen((attendance) {
      if (mounted) {
        setState(() {
          _isAttendanceMarked = attendance != null;
          _attendanceStatus = attendance?.status ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _attendanceSubscription?.cancel();
    _autoSlideTimer?.cancel();
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
          final records = await _attendanceService.getClassAttendance(
              compositeId, DateTime.now());
          int present = 0;
          int absent = 0;
          for (var r in records) {
            if (r.status == 'present') {
              present++;
            } else if (r.status == 'absent') {
              absent++;
            }
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

      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final now = DateTime.now();
      final currentDay = days[now.weekday - 1];
      final dateStr = "${now.year}-${now.month}-${now.day}";

      // Reset/Fetch dismissals
      if (_lastFetchDate != dateStr) {
        _dismissedSessionKeys.clear();
        final storedDismissals = await _dismissalService.getDismissedSessions(user.uid);
        _dismissedSessionKeys.addAll(storedDismissals);
        _lastFetchDate = dateStr;
      }

      final rawSchedule = user.schedule.where((e) =>
      e['day']?.toLowerCase() == currentDay.toLowerCase()).toList();

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

        final records = await _attendanceService.getClassAttendance(
            compositeId, now);

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

      if (mounted) {
        _startAutoSlide();
      }
    } catch (e) {
      debugPrint("Error fetching dashboard statistics: $e");
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

  Future<void> _markTeacherAttendance(UserModel user, String status) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final attendance = TeacherAttendanceModel(
        teacherId: user.uid, 
        teacherName: user.name, 
        date: today, 
        status: status, 
        timestamp: now
      );

      await _teacherAttendanceService.markAttendance(attendance);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.attendanceMarkedSuccess), 
          backgroundColor: Colors.green
        ));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildTeacherAttendanceCard(UserModel? user, bool isDark) {
     if (user == null) return const SizedBox.shrink();

     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: isDark ? const Color(0xFF1E2130) : Colors.white,
         borderRadius: BorderRadius.circular(24),
         boxShadow: [
           if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.myAttendance,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAttendanceMarked 
                        ? (_attendanceStatus == 'present' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1))
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                     _isAttendanceMarked 
                        ? (_attendanceStatus == 'present' ? AppLocalizations.of(context)!.present : AppLocalizations.of(context)!.absent)
                        : AppLocalizations.of(context)!.notMarked,
                     style: TextStyle(
                       color: _isAttendanceMarked 
                          ? (_attendanceStatus == 'present' ? Colors.green : Colors.red)
                          : Colors.orange, 
                       fontWeight: FontWeight.bold, 
                       fontSize: 12
                     ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isAttendanceMarked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: (_attendanceStatus == 'present' ? Colors.green : Colors.red).withValues(alpha: 0.05),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: (_attendanceStatus == 'present' ? Colors.green : Colors.red).withValues(alpha: 0.2)),
                 ),
                 child: Row(
                   children: [
                      Icon(
                        _attendanceStatus == 'present' ? Icons.check_circle : Icons.cancel, 
                        color: _attendanceStatus == 'present' ? Colors.green : Colors.red
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You have marked yourself as ${_attendanceStatus == 'present' ? 'Present' : 'Absent'} today.",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textPrimary,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                   ],
                 ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markTeacherAttendance(user, 'present'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(AppLocalizations.of(context)!.markPresent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                   Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markTeacherAttendance(user, 'absent'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(AppLocalizations.of(context)!.markAbsent),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
         ],
       ),
     );
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_classStats.isEmpty || !mounted) {
        timer.cancel();
        return;
      }
      if (_currentPage < _classStats.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = _currentUser ?? authService.currentUser;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(authService.currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        UserModel? liveUser;
        if (snapshot.hasData && snapshot.data!.exists) {
          liveUser = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          // Optionally refresh dashboard data if schedule changed significantly
          // For now, we'll use the liveUser for calendar and quick actions
        }
        
        final displayUser = liveUser ?? user;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _isLoading 
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 100),
                          child: CircularProgressIndicator(color: AppColors.teacherRole),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, displayUser, authService, textColor, subTextColor),
                          const SizedBox(height: 24),
                          if (displayUser?.assignedClasses.isEmpty ?? true)
                            _buildNoClassesDashboard(textColor, subTextColor, isDark)
                          else ...[
                            _buildAttendanceSummaryCard(isDark),
                            const SizedBox(height: 30),
                            _buildDailyScheduleCard(displayUser, textColor, subTextColor),
                            const SizedBox(height: 30),
                            _buildEventsSection(context, isDark, textColor, subTextColor),
                            const SizedBox(height: 30),
                            _buildTeacherAttendanceCard(displayUser, isDark),
                            const SizedBox(height: 30),
                            Text(
                              AppLocalizations.of(context)!.quickActions,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildQuickActionsGrid(context, isDark, displayUser),
                            const SizedBox(height: 30),
                            _buildClassCalendar(context, displayUser, textColor, subTextColor, isDark),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, AuthService authService, Color textColor, Color subTextColor) { // Added BuildContext context here
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                '${AppLocalizations.of(context)!.hello},',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 16,
                ),
              ),
              Text(
                user?.name ?? 'Professor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
             IconButton(
               onPressed: () {
                 final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
                 if (localeProvider.isUrdu) {
                   localeProvider.setLocale(const Locale('en'));
                 } else {
                   localeProvider.setLocale(const Locale('ur'));
                 }
               },
               icon: Icon(Icons.language, color: textColor),
               tooltip: 'Change Language',
             ),
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
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                backgroundImage: user?.imageUrl != null && user!.imageUrl.isNotEmpty
                    ? (user.imageUrl.startsWith('http')
                        ? NetworkImage(user.imageUrl)
                        : MemoryImage(base64Decode(user.imageUrl))) as ImageProvider
                    : null,
                child: (user?.imageUrl == null || user!.imageUrl.isEmpty) 
                    ? const Icon(Icons.person) 
                    : null,
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
                  color: _currentPage == index ? AppColors.teacherRole : AppColors.teacherRole.withValues(alpha: 0.2),
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
              color: Colors.black.withValues(alpha: 0.05),
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
        color: color.withValues(alpha: 0.1),
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
    final cardHeight = math.max(160.0, screenHeight * 0.22); // Reduced height

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.dailySchedule,
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
        const SizedBox(height: 12), // Reduced spacing
        SizedBox(
          height: cardHeight, // Responsive height
          child: PageView.builder(
            controller: _schedulePageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSchedulePage = index),
            itemCount: visibleSessions.length,
            itemBuilder: (context, index) {
              final session = visibleSessions[index];
              final upNextSession = visibleSessions.firstWhereOrNull((s) => !(s['hasPassed'] ?? false));
              final isUpNext = session == upNextSession;
              
              return _buildScheduleSlide(session, isUpNext);
            },
          ),
        ),
        if (visibleSessions.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              visibleSessions.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentSchedulePage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentSchedulePage == index ? AppColors.teacherRole : AppColors.teacherRole.withValues(alpha: 0.2),
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
    return Column(
      children: [
        const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 40),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.noClassScheduled,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          AppLocalizations.of(context)!.enjoyYourDay,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildScheduleSlide(Map<String, dynamic> session, bool isUpNext) {
    final hasPassed = session['hasPassed'] ?? false;
    final isRed = hasPassed; // Missed class turns red
    final sessionKey = "${session['classId']}_${session['section']}_${session['time']}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), // Full width (0 margin)
      padding: const EdgeInsets.all(16), // Squeezed padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRed 
            ? [const Color(0xFFFF4B2B), const Color(0xFFFF416C)] // Red gradient
            : [const Color(0xFF2E63F6), const Color(0xFF1440C7)], // Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // Slightly smaller radius
        boxShadow: [
          BoxShadow(
            color: (isRed ? Colors.red : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildScheduleDetails(session, isUpNext),
          if (isRed)
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                onPressed: () async {
                  setState(() {
                    _dismissedSessionKeys.add(sessionKey);
                  });
                  await _dismissalService.saveDismissedSession(_currentUser!.uid, sessionKey);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                tooltip: 'Dismiss missed class',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
        // Top Row: UpNext/Time (Left) -- Grade (Right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isUpNext) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Text('⚡ NEXT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('🕒 ', style: TextStyle(fontSize: 12)),
                      Text(
                        session['time'] ?? 'TBD',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Grade moved to Top Right
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Grade ${session['classId']}-${session['section']}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        
        const Spacer(),

        // Middle: Subject
        Text(
          session['subject'] ?? 'No Subject',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24, // Slightly smaller
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        
        const SizedBox(height: 8),

        // Bottom: Day (Moved Closer to Subject)
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(
              '${session['day'] ?? 'Today'}',
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4), // Small bottom padding
      ],
    );
  }
  
  Widget _buildQuickActionsGrid(BuildContext context, bool isDark, UserModel? user) {
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
          AppLocalizations.of(context)!.attendance,
          Icons.person_outline,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Attendance'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          AppLocalizations.of(context)!.students,
          Icons.people_outline,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Student List'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          AppLocalizations.of(context)!.results,
          Icons.description_outlined,
          Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Exam'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          AppLocalizations.of(context)!.assignments,
          Icons.assignment_outlined,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassSelectionScreen(assessmentType: 'Assignment'))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          'Timetable',
          Icons.calendar_month_outlined,
          Colors.pink,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherTimetableScreen(teacherUid: user!.uid))),
          isDark
        ),
        _buildDarkActionCard(
          context,
          'Broadcast',
          Icons.campaign_outlined,
          Colors.orange,
          () => _showBroadcastDialog(context, user),
          isDark
        ),
      ],
    );
  }

  void _showBroadcastDialog(BuildContext context, UserModel? user) {
    if (user == null) return;
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.orange),
            SizedBox(width: 8),
            Text('Broadcast Update'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This message will be sent to ALL parents in your assigned classes.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your announcement...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final msg = controller.text.trim();
                Navigator.pop(context);
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sending broadcast...')),
                );

                // Send notifications to each assigned class topic
                for (var cls in user.assignedClasses) {
                  final classId = cls['classId'];
                  final section = cls['section'];
                  if (classId != null && section != null) {
                    // In a production app, you'd have topics like 'class_1_A'
                    // For now, we'll send a general 'all_parents' or 'all' notification
                    // demonstrating the capability.
                    await NotificationService().sendTopicNotification(
                      topic: 'all_parents', 
                      title: 'Update from ${user.name}',
                      body: msg,
                      data: {
                        'type': 'broadcast',
                        'teacherId': user.uid,
                        'classId': classId,
                        'section': section,
                      },
                    );
                  }
                }

                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('SEND TO ALL'),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161822) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCalendar(BuildContext context, UserModel? user, Color textColor, Color subTextColor, bool isDark) {
    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
    // final daysInMonth = _getDaysInMonth(now); // Removed unused variable

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.myTeachingCalendar,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherTimetableScreen(teacherUid: user.uid))),
          child: Container(
            padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161822) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_getMonthName(now.month)} ${now.year}",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.calendar_month, color: AppColors.teacherRole),
                ],
              ),
              const SizedBox(height: 20),
              
              // Days of Week Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: 30, // Fixed width for alignment
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: subTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              
              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 42, // 6 rows * 7 days
                itemBuilder: (context, index) {
                  // Calculate date for this cell
                  final dayOffset = index - (startingWeekday - 1);
                  final cellDate = firstDayOfMonth.add(Duration(days: dayOffset));
                  
                  // Check if date is within current month
                  final isCurrentMonth = cellDate.month == now.month;
                  if (!isCurrentMonth) return const SizedBox.shrink();

                  final isToday = cellDate.year == now.year && 
                                 cellDate.month == now.month && 
                                 cellDate.day == now.day;
                  
                  // Check if class is scheduled for this weekday
                  final hasClass = _isClassScheduled(user, cellDate);

                  return Container(
                    decoration: BoxDecoration(
                      color: isToday 
                          ? AppColors.teacherRole 
                          : (hasClass ? AppColors.teacherRole.withValues(alpha: 0.1) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isToday ? null : (hasClass ? Border.all(color: AppColors.teacherRole.withValues(alpha: 0.5)) : null),
                    ),
                    child: Center(
                      child: Text(
                        "${cellDate.day}",
                        style: TextStyle(
                          color: isToday 
                              ? Colors.white 
                              : (hasClass ? (isDark ? Colors.white : AppColors.textPrimary) : subTextColor.withValues(alpha: 0.5)),
                          fontWeight: isToday || hasClass ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
  // Helper: Get Month Name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Helper: Check if class is scheduled for a specific date
  bool _isClassScheduled(UserModel user, DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final startOfWeek = date.weekday - 1; // 0 for Monday
    
    // Safety check
    if (startOfWeek < 0 || startOfWeek >= weekdays.length) return false;
    
    final dayName = weekdays[startOfWeek];
    
    return user.schedule.any((session) => 
        (session['day'])?.toLowerCase() == dayName.toLowerCase());
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
            AppLocalizations.of(context)!.readyToStart,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noClassesAssigned,
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
            child: Text(AppLocalizations.of(context)!.refreshDashboard, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    final api = SchoolApi();
    final mq = MediaQuery.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'School Events',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to a dedicated events list if needed
              },
              child: Text('View All', style: TextStyle(color: AppColors.teacherRole)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SchoolEventModel>>(
          stream: api.getEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            
            final allEvents = snapshot.data ?? [];
            final today = DateTime.now();
            final todayEvents = allEvents.where((e) => 
               e.date.year == today.year && 
               e.date.month == today.month && 
               e.date.day == today.day
            ).toList();

            if (todayEvents.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161822) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_note, color: subTextColor.withValues(alpha: 0.5)),
                    const SizedBox(width: 12),
                    Text(
                      'No events scheduled for today',
                      style: TextStyle(color: subTextColor, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: todayEvents.length,
                itemBuilder: (context, index) {
                  final event = todayEvents[index];
                  return Container(
                    width: mq.size.width * 0.8,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.teacherRole, AppColors.teacherRole.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teacherRole.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.location,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          event.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
