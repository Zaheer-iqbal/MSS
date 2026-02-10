import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../school/services/school_api.dart';
import 'staff_list_screen.dart';

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
              name: user?.name ?? 'Head Teacher',
              role: 'Head Teacher',
              roleColor: AppColors.headTeacherRole,
              onLogout: () => authService.signOut(),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'School Overview',
                    style: TextStyle(
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
                          title: 'Total Students',
                          value: '${snapshot.data ?? 0}',
                          icon: Icons.school,
                          color: Colors.indigo,
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: SchoolApi().getTeacherCount(),
                        builder: (context, snapshot) => StatCard(
                          title: 'Total Staff',
                          value: '${snapshot.data ?? 0}',
                          icon: Icons.badge,
                          color: Colors.teal,
                        ),
                      ),
                      const StatCard(
                        title: 'Fee Status',
                        value: '78%', // Placeholder
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                      const StatCard(
                        title: 'Rating',
                        value: '4.8', // Placeholder
                        icon: Icons.star,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Administrative Tools',
                    style: TextStyle(
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
                        label: 'Staff',
                        icon: Icons.assignment_ind,
                        color: AppColors.headTeacherRole,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StaffListScreen()),
                        ),
                      ),
                      ActionIcon(
                        label: 'Admissions',
                        icon: Icons.group_add,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'Fees',
                        icon: Icons.payments,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'Events',
                        icon: Icons.event,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'Reports',
                        icon: Icons.analytics,
                        color: AppColors.headTeacherRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'Settings',
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
