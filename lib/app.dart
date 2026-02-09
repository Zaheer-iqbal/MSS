import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/constants/app_colors.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/school/screens/school_dashboard.dart';
import '../features/teacher/screens/teacher_dashboard.dart';
import '../features/head_teacher/screens/head_dashboard.dart';
import '../features/parent/screens/parent_dashboard.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'MSS School',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (authService.isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (user == null) {
      return const RoleSelectionScreen();
    }

    switch (user.role) {
      case 'school':
        return const SchoolDashboard();
      case 'teacher':
        return const TeacherDashboard();
      case 'head_teacher':
        return const HeadDashboard();
      case 'parent':
        if (authService.currentStudent != null) {
          return ParentDashboardScreen(student: authService.currentStudent!);
        }
        return const RoleSelectionScreen();
      default:
        return const RoleSelectionScreen();
    }
  }
}
