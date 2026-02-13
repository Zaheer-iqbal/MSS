import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/auth_service.dart';
import 'head_dashboard.dart';
import 'staff_list_screen.dart';
import '../../teacher/screens/chat_list_screen.dart';
import 'head_teacher_profile_screen.dart';

class HeadTeacherMainScreen extends StatefulWidget {
  const HeadTeacherMainScreen({super.key});

  @override
  State<HeadTeacherMainScreen> createState() => _HeadTeacherMainScreenState();
}

class _HeadTeacherMainScreenState extends State<HeadTeacherMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> screens = [
      const HeadDashboard(),
      const StaffListScreen(),
      const ChatListScreen(),
      HeadTeacherProfileScreen(user: user),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F111A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.white,
          selectedItemColor: AppColors.headTeacherRole,
          unselectedItemColor: isDark ? Colors.grey : AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Staff'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
