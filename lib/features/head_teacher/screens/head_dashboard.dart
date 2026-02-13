import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../school/services/school_api.dart';
import 'staff_list_screen.dart';
import 'head_teacher_profile_screen.dart';
import 'student_list_by_class_screen.dart';
import 'events_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class HeadDashboard extends StatelessWidget {
  const HeadDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              name: user?.name ?? AppLocalizations.of(context)!.headTeacher,
              role: AppLocalizations.of(context)!.headTeacher,
              roleColor: AppColors.headTeacherRole,
              imageUrl: user?.imageUrl,
              onLogout: () => authService.signOut(),
              onAvatarTap: () {
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HeadTeacherProfileScreen(user: user),
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.schoolOverview,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      StreamBuilder<int>(
                        stream: SchoolApi().getStudentCount(),
                        builder: (context, snapshot) => StatCard(
                          title: AppLocalizations.of(context)!.totalStudents,
                          value: '${snapshot.data ?? 0}',
                          icon: Icons.school,
                          color: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StudentListByClassScreen(),
                            ),
                          ),
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: SchoolApi().getTeacherCount(),
                        builder: (context, snapshot) => StatCard(
                          title: AppLocalizations.of(context)!.totalStaff,
                          value: '${snapshot.data ?? 0}',
                          icon: Icons.badge,
                          color: Colors.teal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StaffListScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.administrativeTools,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    children: [
                      ActionIcon(
                        label: AppLocalizations.of(context)!.staff,
                        icon: Icons.assignment_ind,
                        color: AppColors.headTeacherRole,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StaffListScreen(),
                          ),
                        ),
                      ),
                      ActionIcon(
                        label: AppLocalizations.of(context)!.admissions,
                        icon: Icons.group_add,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: AppLocalizations.of(context)!.events,
                        icon: Icons.event,
                        color: AppColors.headTeacherRole,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EventsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Overall Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildOverallReportsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallReportsSection() {
    final api = SchoolApi();
    return Column(
      children: [
        _buildAttendanceCard(
          title: 'Overall Student Attendance',
          stream: api.getOverallCumulativeStudentAttendance(),
          color: Colors.green,
          noDataMessage: 'No student attendance records found yet',
        ),
        const SizedBox(height: 16),
        _buildAttendanceCard(
          title: 'Overall Teacher Attendance',
          stream: api.getOverallCumulativeTeacherAttendance(),
          color: Colors.indigo,
          noDataMessage: 'No teacher attendance records found yet',
        ),
      ],
    );
  }

  Widget _buildAttendanceCard({
    required String title,
    required Stream<Map<String, int>> stream,
    required Color color,
    required String noDataMessage,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          StreamBuilder<Map<String, int>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data =
                  snapshot.data ??
                  {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
              final total = data['total']?.toDouble() ?? 0.0;

              if (total == 0) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      noDataMessage,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                            value: (data['present'] ?? 0).toDouble(),
                            color: color,
                            radius: 10,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (data['absent'] ?? 0).toDouble(),
                            color: Colors.red.shade400,
                            radius: 10,
                            showTitle: false,
                          ),
                          if (data.containsKey('late'))
                            PieChartSectionData(
                              value: (data['late'] ?? 0).toDouble(),
                              color: Colors.orange.shade400,
                              radius: 10,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatusRow('Present', data['present'] ?? 0, color),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Absent',
                          data['absent'] ?? 0,
                          Colors.red.shade400,
                        ),
                        if (data.containsKey('late')) ...[
                          const SizedBox(height: 8),
                          _buildStatusRow(
                            'Late',
                            data['late'] ?? 0,
                            Colors.orange.shade400,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
