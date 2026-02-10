import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
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

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    // Use assigned classes from user model
    final classes = user?.assignedClasses ?? [];
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, user, authService, textColor, subTextColor), // Passed context here
              const SizedBox(height: 30),
              _buildDailyScheduleCard(user),
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
              const SizedBox(height: 30),
              _buildPerformanceAnalytics(textColor, subTextColor, isDark),
              const SizedBox(height: 80), 
            ],
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

  Widget _buildDailyScheduleCard(UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E63F6), Color(0xFF1440C7)], // Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // View Calendar
                },
                child: const Text(
                  'View Calendar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.white24,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: const Text('UP NEXT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
               ),
               const Spacer(),
               const Icon(Icons.location_on, color: Colors.white70, size: 14),
               const SizedBox(width: 4),
               const Text('Room 402', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Advanced Mathematics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Grade 10B • Calculus & Geometry',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                   Icon(Icons.access_time, color: Colors.white70, size: 16),
                   SizedBox(width: 6),
                   Text('10:30 AM - 11:45 AM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1440C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('PREPARE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
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
          'Notices',
          Icons.campaign_outlined,
          Colors.orange,
          () {}, // TODO: Notices screen
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
}

