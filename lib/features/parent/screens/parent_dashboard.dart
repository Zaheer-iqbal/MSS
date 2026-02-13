import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/services/attendance_service.dart';
import '../../student/services/student_api.dart';
import '../../student/services/student_schedule_service.dart';
import 'child_progress.dart';
import 'package:intl/intl.dart';

class ParentDashboardScreen extends StatefulWidget {
  final StudentModel student;
  const ParentDashboardScreen({super.key, required this.student});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _studentApi = StudentApi();
  final _attendanceService = AttendanceService();
  final _scheduleService = StudentScheduleService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentModel?>(
      stream: _studentApi.streamStudentById(widget.student.id),
      builder: (context, snapshot) {
        final student = snapshot.data ?? widget.student;

        return Container(
          color: AppColors.background,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(student),
                  const SizedBox(height: 24),
                  _buildStudentProfileHeader(),
                  _buildStudentProfileCard(student),
                  const SizedBox(height: 24),
                  _buildAttendanceSection(student),
                  const SizedBox(height: 24),
                  _buildScheduleSection(student),
                  const SizedBox(height: 24),
                  _buildCalendarSection(student),
                  const SizedBox(height: 24),
                  _buildAcademicSection(student),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(StudentModel student) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parent Portal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            Text(
              'Parent of ${student.name}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await Provider.of<AuthService>(context, listen: false).signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                  (route) => false,
                );
              },
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentProfileHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        "STUDENT PROFILE",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStudentProfileCard(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.parentRole, Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.parentRole.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: (student.imageUrl.isNotEmpty && student.imageUrl.startsWith('http')) 
                  ? NetworkImage(student.imageUrl) 
                  : null,
              child: student.imageUrl.isEmpty 
                  ? const Icon(Icons.person, size: 36, color: AppColors.parentRole) 
                  : (!student.imageUrl.startsWith('http') 
                      ? ClipOval(child: Image.memory(base64Decode(student.imageUrl), fit: BoxFit.cover, width: 64, height: 64)) 
                      : null),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Class ${student.classId}-${student.section} | Roll No: ${student.rollNo}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(StudentModel student) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendanceService.getStudentAttendance(student.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final total = records.length;
        final present = records.where((r) => r.status == 'present').length;
        final absent = records.where((r) => r.status == 'absent').length;
        final late = records.where((r) => r.status == 'late').length;
        final percent = total > 0 ? (present / total) : 0.0;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChildProgress(
                  studentId: student.id,
                  studentName: student.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Attendance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                color: Colors.grey.shade100,
                                strokeWidth: 10,
                              ),
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: percent,
                                color: Colors.green,
                                backgroundColor: Colors.transparent,
                                strokeWidth: 10,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${(percent * 100).toInt()}%",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimary),
                                ),
                                const Text("Present", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildStatRow('Present', '$present Days', Colors.green),
                          const SizedBox(height: 12),
                          _buildStatRow('Absent', '$absent Days', Colors.red),
                          const SizedBox(height: 12),
                          _buildStatRow('Late', '$late Days', Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildScheduleSection(StudentModel student) {
        return StreamBuilder<List<Map<String, String>>>(
          stream: _scheduleService.getStudentSchedule(student.classId, student.section),
          builder: (context, snapshot) {
            final schedule = snapshot.data ?? [];
            
            // Group by day
            final Map<String, List<Map<String, String>>> groupedSchedule = {};
            final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            for (var day in days) {
              groupedSchedule[day] = schedule.where((e) => e['day'] == day).toList();
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_view_week, color: AppColors.parentRole),
                          SizedBox(width: 8),
                          Text("Weekly Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        "${schedule.length} Classes",
                        style: const TextStyle(color: AppColors.parentRole, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (schedule.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No classes scheduled.", style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    DefaultTabController(
                      length: 7,
                      initialIndex: DateTime.now().weekday - 1,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            labelColor: AppColors.parentRole,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: AppColors.parentRole,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            tabs: days.map((day) => Tab(text: day.substring(0, 3))).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: TabBarView(
                              children: days.map((day) {
                                final dayClasses = groupedSchedule[day] ?? [];
                                if (dayClasses.isEmpty) {
                                  return const Center(child: Text("No classes", style: TextStyle(color: Colors.grey, fontSize: 12)));
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: dayClasses.length,
                                  itemBuilder: (context, index) {
                                    final entry = dayClasses[index];
                                    return _buildScheduleItem(entry);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
        );
  }

  Widget _buildCalendarSection(StudentModel student) {
    // Current date logic
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday

    return StreamBuilder<List<Map<String, String>>>(
      stream: _scheduleService.getStudentSchedule(student.classId, student.section),
      builder: (context, snapshot) {
        final schedule = snapshot.data ?? [];
        final scheduledDays = schedule.map((e) => e['day']).toSet();
        final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                    children: [
                       Icon(Icons.date_range, color: AppColors.parentRole),
                      const SizedBox(width: 8),
                      const Text("Calendar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(now),
                    style: const TextStyle(color: AppColors.parentRole, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Day Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text("M", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("T", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("W", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("T", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("F", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              // Simple Grid Layout for Calendar
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: daysInMonth + startWeekday - 1,
                itemBuilder: (context, index) {
                  if (index < startWeekday - 1) return const SizedBox.shrink();
                  
                  final day = index - startWeekday + 2;
                  final date = DateTime(now.year, now.month, day);
                  final isToday = day == now.day;
                  final dayName = weekdays[date.weekday - 1];
                  final hasClass = scheduledDays.contains(dayName);
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.parentRole : (hasClass ? AppColors.parentRole.withValues(alpha: 0.1) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday ? null : (hasClass ? Border.all(color: AppColors.parentRole.withValues(alpha: 0.3)) : null),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.toString(),
                            style: TextStyle(
                              color: isToday ? Colors.white : AppColors.textPrimary,
                              fontWeight: isToday || hasClass ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          if (hasClass && !isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(color: AppColors.parentRole, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcademicSection(StudentModel student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(24),
         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: AppColors.parentRole),
              SizedBox(width: 8),
              Text("Academic Updates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (student.assignmentMarks.isEmpty && 
              student.quizMarks.isEmpty && 
              student.midTermMarks.isEmpty &&
              student.finalTermMarks.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                    const Text("No academic records yet.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )),
          _buildMarksCategory("Assignments", student.assignmentMarks),
          _buildMarksCategory("Quizzes", student.quizMarks),
          _buildMarksCategory("Mid-term", student.midTermMarks),
          _buildMarksCategory("Final-term", student.finalTermMarks),
        ],
      ),
    );
  }

  Widget _buildMarksCategory(String title, Map<String, dynamic> marks) {
    if (marks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        ...marks.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.parentRole.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.parentRole),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
  Widget _buildScheduleItem(Map<String, String> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.parentRole.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.parentRole.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time_rounded, color: AppColors.parentRole, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['time'] ?? "TBD",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.parentRole, fontSize: 13),
                ),
                Text(
                  entry['subject'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Teacher: ${entry['teacherName'] ?? 'Assigned'}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
