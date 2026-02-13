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
import 'reports_screen.dart';

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
                      builder: (context) => HeadTeacherProfileScreen(user: user),
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
                              builder: (context) => const StudentListByClassScreen(),
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
                  _buildAnalyticsSection(context),
                  const SizedBox(height: 32),
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
                          MaterialPageRoute(builder: (context) => const StaffListScreen()),
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
                          MaterialPageRoute(builder: (context) => const EventsScreen()),
                        ),
                      ),
                      ActionIcon(
                        label: AppLocalizations.of(context)!.reports,
                        icon: Icons.analytics,
                        color: AppColors.headTeacherRole,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReportsScreen()),
                        ),
                      ),
                      ActionIcon(
                        label: AppLocalizations.of(context)!.settings,
                        icon: Icons.settings,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attendance Density', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Live', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar('Mon', 0.6, Colors.indigo),
                    _buildBar('Tue', 0.8, Colors.teal),
                    _buildBar('Wed', 0.4, Colors.orange),
                    _buildBar('Thu', 0.9, Colors.pink),
                    _buildBar('Fri', 0.7, Colors.blue),
                    _buildBar('Sat', 0.3, Colors.amber),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String label, double heightFactor, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
