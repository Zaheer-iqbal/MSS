import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/providers/locale_provider.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/school/screens/school_dashboard.dart';
import '../features/teacher/screens/teacher_main_screen.dart';
import '../features/head_teacher/screens/head_teacher_main_screen.dart';
import '../features/parent/screens/parent_dashboard.dart';
import '../features/student/screens/student_main_screen.dart';
import 'l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'MSS School',
        themeMode: themeProvider.themeMode,
        theme: ThemeProvider.lightTheme,
        darkTheme: ThemeProvider.darkTheme,
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ur'),
        ],
        home: const SplashScreen(),
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
        return const TeacherMainScreen();
      case 'student':
        if (authService.currentStudent != null) {
           return StudentMainScreen(student: authService.currentStudent!);
        }
        // Fallback if student data is missing but role is student (shouldn't happen ideally)
        return const RoleSelectionScreen(); 
      case 'head_teacher':
        return const HeadTeacherMainScreen();
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
