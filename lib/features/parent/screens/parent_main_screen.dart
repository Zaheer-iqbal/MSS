import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../../core/providers/theme_provider.dart';
import '../../teacher/screens/chat_list_screen.dart';
import 'parent_dashboard.dart';
import '../../teacher/screens/student_profile_screen.dart'; 
import '../../chat/services/chat_service.dart';
import '../../../core/services/auth_service.dart';

class ParentMainScreen extends StatefulWidget {
  final StudentModel student;
  const ParentMainScreen({super.key, required this.student});

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  int _currentIndex = 0;
  final ChatService _chatService = ChatService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ParentDashboardScreen(student: widget.student),
      const ChatListScreen(),
      StudentProfileScreen(student: widget.student),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F111A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.white,
          selectedItemColor: AppColors.parentRole, 
          unselectedItemColor: isDark ? Colors.grey : AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: _chatService.getTotalUnreadCount(context.read<AuthService>().currentUser?.uid ?? ''),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
