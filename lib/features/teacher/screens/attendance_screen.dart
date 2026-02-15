import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../student/services/student_api.dart';
import 'attendance_summary_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String section;
  final String? subject;

  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.section,
    this.subject, // Optional initial subject
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final StudentApi _studentApi = StudentApi();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final Map<String, String> _attendanceMap = {};
  List<StudentModel> _students = [];

  bool _checkingStatus = true;
  String? _selectedSubject;
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.subject;
    _loadAvailableSubjects();
  }

  void _loadAvailableSubjects() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      // Get unique subjects for this class/section from teacher's schedule or assignedClasses
      // If subjects aren't explicitly in assignedClasses, we look at schedule
      final subjects = user.schedule
          .where((s) => s['classId'] == widget.classId && s['section'] == widget.section)
          .map((s) => s['subject'] ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      
      setState(() {
        _availableSubjects = subjects;
        if (_selectedSubject == null && subjects.isNotEmpty) {
          _selectedSubject = subjects.first;
        }
      });
    }
    _checkTodayAttendance();
  }

  Future<void> _checkTodayAttendance() async {
    if (_selectedSubject == null) {
      if (mounted) setState(() => _checkingStatus = false);
      return;
    }

    final compositeId = "${widget.classId}_${widget.section}".toLowerCase();
    final todayRecords = await _attendanceService.getClassAttendance(
      compositeId,
      DateTime.now(),
      subject: _selectedSubject,
    );

    if (todayRecords.isNotEmpty && mounted) {
      // Attendance already marked, redirect to summary
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceSummaryScreen(
            classId: widget.classId,
            section: widget.section,
            subject: _selectedSubject!,
          ),
        ),
      );
    } else {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;

    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final teacherId = authService.currentUser?.uid ?? 'unknown';

    try {
      for (var student in _students) {
        final status = _attendanceMap[student.id] ?? 'present';
        final record = AttendanceRecord(
          studentId: student.id,
          studentName: student.name,
          date: _selectedDate,
          status: status,
          markedBy: teacherId,
          classId: "${widget.classId}_${widget.section}".toLowerCase(),
          subject: _selectedSubject ?? 'General',
        );
        await _attendanceService.markAttendance(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance for $_selectedSubject marked successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceSummaryScreen(
              classId: widget.classId,
              section: widget.section,
              subject: _selectedSubject ?? 'General',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Attendance: ${widget.classId}-${widget.section}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: _studentApi.getStudentsByClass(widget.classId, widget.section),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          _students = snapshot.data ?? [];

          if (_students.isEmpty) {
            return const Center(
              child: Text('No students enrolled in this class.'),
            );
          }

          // Initialize attendance map for new students if not set
          for (var student in _students) {
            _attendanceMap.putIfAbsent(student.id, () => 'present');
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class ${widget.classId}-${widget.section}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_students.length} Students',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.teacherRole,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          hint: const Text('Select Subject'),
                          items: _availableSubjects.map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(
                                subject,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSubject = val;
                                _checkingStatus = true;
                              });
                              _checkTodayAttendance();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final status = _attendanceMap[student.id];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.teacherRole.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              student.name[0],
                              style: const TextStyle(
                                color: AppColors.teacherRole,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildStatusToggle(
                            student.id,
                            'P',
                            'present',
                            status == 'present',
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusToggle(
                            student.id,
                            'A',
                            'absent',
                            status == 'absent',
                            Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusToggle(
                            student.id,
                            'L',
                            'late',
                            status == 'late',
                            Colors.orange,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teacherRole,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SUBMIT ATTENDANCE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusToggle(
    String studentId,
    String label,
    String status,
    bool isSelected,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _attendanceMap[studentId] = status),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? null
              : Border.all(color: color.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
