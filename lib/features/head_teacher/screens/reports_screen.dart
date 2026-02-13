import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Reports'),
        backgroundColor: AppColors.headTeacherRole,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildReportCard(context, 'Academic Report', Icons.bar_chart_rounded, Colors.blue),
          _buildReportCard(context, 'Attendance Report', Icons.fact_check_rounded, Colors.green),
          _buildReportCard(context, 'Financial Summary', Icons.pie_chart_rounded, Colors.orange),
          _buildReportCard(context, 'Staff Performance', Icons.trending_up_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
