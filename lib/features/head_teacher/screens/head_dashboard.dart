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
                       StatCard(
                        title: AppLocalizations.of(context)!.feeStatus,
                        value: '78%', // Placeholder
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                       StatCard(
                        title: AppLocalizations.of(context)!.rating,
                        value: '4.8', // Placeholder
                        icon: Icons.star,
                        color: Colors.amber,
                      ),
                    ],
                  ),
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
                        label: AppLocalizations.of(context)!.fees,
                        icon: Icons.payments,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: AppLocalizations.of(context)!.events,
                        icon: Icons.event,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: AppLocalizations.of(context)!.reports,
                        icon: Icons.analytics,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
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
}
