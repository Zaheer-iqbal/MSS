import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/theme_provider.dart';
import 'marks_entry_screen.dart';
import 'attendance_screen.dart';
import 'student_list_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  final String assessmentType; 

  const ClassSelectionScreen({super.key, required this.assessmentType});

  @override
  Widget build(BuildContext context) {
    print(
      'DEBUG: Building ClassSelectionScreen for $assessmentType',
    ); 
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;
    final classes = user?.assignedClasses ?? [];
    final isDark = themeProvider.isDarkMode;

    final backgroundColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF8FAFF);
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardColor = isDark ? const Color(0xFF1E2130) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Classes', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: classes.isEmpty
          ? _buildEmptyState(isDark)
          : Column(
              children: [
                if (classes.isNotEmpty) // Optional: Add a subtle instruction or count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select a class to manage $assessmentType',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: classes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final cls = classes[index];
                      return _buildClassCard(
                        context,
                        cls['classId']!,
                        cls['section']!,
                        index,
                        isDark,
                        cardColor,
                        textColor,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 80,
            color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No classes assigned.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    String classId,
    String section,
    int index,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.teal,
    ];
    final color = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (assessmentType == 'Attendance') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AttendanceScreen(classId: classId, section: section),
                ),
              );
            } else if (assessmentType == 'Student List' ||
                assessmentType == 'View') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentListScreen(classId: classId, section: section),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarksEntryScreen(
                    classId: classId,
                    section: section,
                    assessmentType: assessmentType,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.school_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                
                // Class Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class $classId-$section',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
