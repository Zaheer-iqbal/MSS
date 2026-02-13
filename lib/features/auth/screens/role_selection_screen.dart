import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
                        if (localeProvider.isUrdu) {
                          localeProvider.setLocale(const Locale('en'));
                        } else {
                          localeProvider.setLocale(const Locale('ur'));
                        }
                      },
                      icon: const Icon(Icons.language, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.appAppName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.authWelcomeSub,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _RoleCard(
                        title: AppLocalizations.of(context)!.headTeacher,
                        icon: Icons.military_tech_rounded,
                        color: AppColors.headTeacherRole,
                        role: 'head_teacher',
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        title: AppLocalizations.of(context)!.teacher,
                        icon: Icons.assignment_ind_rounded,
                        color: AppColors.teacherRole,
                        role: 'teacher',
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        title: AppLocalizations.of(context)!.parent,
                        icon: Icons.family_restroom_rounded,
                        color: AppColors.parentRole,
                        role: 'parent',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.loginExisting,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String role;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (role == 'parent') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen(isParent: true)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(role: role),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
