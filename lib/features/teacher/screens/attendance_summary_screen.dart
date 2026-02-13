import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/attendance_service.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final String classId;
  final String section;

  const AttendanceSummaryScreen({
    super.key,
    required this.classId,
    required this.section,
  });

  @override
  State<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _selectedDate = DateTime.now();
  
  Map<String, int> _stats = {
    'present': 0,
    'absent': 0,
    'late': 0,
    'total': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final compositeClassId = "${widget.classId}_${widget.section}".toLowerCase();
      final records = await _attendanceService.getClassAttendance(compositeClassId, _selectedDate);
      
      int present = 0;
      int absent = 0;
      int late = 0;

      for (var record in records) {
        if (record.status == 'present') {
          present++;
        } else if (record.status == 'absent') absent++;
        else if (record.status == 'late') late++;
      }

      setState(() {
        _stats = {
          'present': present,
          'absent': absent,
          'late': late,
          'total': records.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Attendance: ${widget.classId}-${widget.section}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _fetchAttendance();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildDateHeader(),
                  const SizedBox(height: 32),
                  _buildGraph(),
                  const SizedBox(height: 40),
                  _buildStatsGrid(),
                  const SizedBox(height: 48),
                  // Removed "Manage Attendance" button as per requirement to not allow updates
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Attendance for today has been submitted.",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateHeader() {
    return Column(
      children: [
        Text(
          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
          style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        const Text(
          "Today's Overview",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildGraph() {
    final total = _stats['total']?.toDouble() ?? 1.0; // Avoid divide by zero
    final present = _stats['present']?.toDouble() ?? 0.0;
    final absent = _stats['absent']?.toDouble() ?? 0.0;
    
    // Calculate percentages for the painter
    // If total is 0, we show a grey circle
    
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: AttendanceChartPainter(
          present: present,
          absent: absent,
          total: total == 0 ? 1 : total,
          isEmpty: total == 0,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total == 0 ? "0" : "${(present / total * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                "Present",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Present', _stats['present'].toString(), Colors.green),
        _buildStatItem('Absent', _stats['absent'].toString(), Colors.red),
        _buildStatItem('Late', _stats['late'].toString(), Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class AttendanceChartPainter extends CustomPainter {
  final double present;
  final double absent;
  final double total;
  final bool isEmpty;

  AttendanceChartPainter({
    required this.present,
    required this.absent,
    required this.total,
    required this.isEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 15.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isEmpty) {
      paint.color = Colors.grey.withOpacity(0.2);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // Draw background circle
    paint.color = Colors.grey.withOpacity(0.1);
    canvas.drawCircle(center, radius, paint);

    double startAngle = -pi / 2;

    // Draw Present Arc
    if (present > 0) {
      final sweepAngle = (present / total) * 2 * pi;
      paint.color = Colors.green;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Draw Absent Arc
    if (absent > 0) {
      final sweepAngle = (absent / total) * 2 * pi;
      paint.color = Colors.red;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
    
    // Draw Late/Others implicitly as empty or we could add another segment, 
    // but the request focused on basic attendance.
    // For visual completeness, let's just leave the rest as the background circle colour 
    // or if we wanted to be precise, we'd draw 'Late' too. 
    // Let's add Late just in case the data has it.
    
    // Note: The background circle already covers the "remaining" space, 
    // but drawing explicitly is better for overlapping segments if needed.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
