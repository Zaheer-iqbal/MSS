import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../head_teacher/screens/staff_list_screen.dart';
import '../../teacher/screens/student_list_screen.dart';
import '../services/school_api.dart';

class SchoolDashboard extends StatelessWidget {
  const SchoolDashboard({super.key});

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
              name: user?.name ?? 'School Admin',
              role: 'School Owner',
              roleColor: AppColors.schoolRole,
              onLogout: () => authService.signOut(),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Institutional Performance',
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
                      const StatCard(
                        title: 'Revenue (MTD)',
                        value: '₹0', // Placeholder
                        icon: Icons.currency_rupee,
                        color: Colors.green,
                      ),
                      StreamBuilder<int>(
                        stream: SchoolApi().getStudentCount(),
                        builder: (context, snapshot) => StatCard(
                          title: 'Active Students',
                          value: '${snapshot.data ?? 0}',
                          icon: Icons.people_alt,
                          color: Colors.blue,
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: SchoolApi().getTeacherCount(),
                        builder: (context, snapshot) => StatCard(
                          title: 'Total Teachers',
                          value: '${snapshot.data ?? 0}',
                          icon: Icons.record_voice_over,
                          color: Colors.purple,
                        ),
                      ),
                      const StatCard(
                        title: 'Pending Apps',
                        value: '0', // Placeholder
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Master Controls',
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
                        label: 'Academics',
                        icon: Icons.history_edu,
                        color: AppColors.schoolRole,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentListScreen(),
                          ),
                        ),
                      ),
                      ActionIcon(
                        label: 'Finance',
                        icon: Icons.account_balance,
                        color: AppColors.schoolRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'HR / Staff',
                        icon: Icons.groups,
                        color: AppColors.schoolRole,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StaffListScreen(),
                          ),
                        ),
                      ),
                      ActionIcon(
                        label: 'Inventory',
                        icon: Icons.inventory_2,
                        color: AppColors.schoolRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'Transport',
                        icon: Icons.local_shipping,
                        color: AppColors.schoolRole,
                        onTap: () {},
                      ),
                      ActionIcon(
                        label: 'Communications',
                        icon: Icons.campaign,
                        color: AppColors.schoolRole,
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
