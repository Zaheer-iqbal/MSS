import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/auth_service.dart';
import '../../student/services/student_api.dart';
import '../../teacher/screens/attendance_summary_screen.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/models/attendance_model.dart';
import 'manage_student_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentModel student;
  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _studentApi = StudentApi();
  final _attendanceService = AttendanceService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _userRole = authService.currentUser?.role;
  }

  Future<void> _updateMarks(StudentModel currentStudent, String type, Map<String, dynamic> newMarks) async {
    final updatedStudent = StudentModel(
      id: currentStudent.id,
      name: currentStudent.name,
      rollNo: currentStudent.rollNo,
      classId: currentStudent.classId,
      section: currentStudent.section,
      parentEmail: currentStudent.parentEmail,
      fatherName: currentStudent.fatherName,
      phone: currentStudent.phone,
      address: currentStudent.address,
      imageUrl: currentStudent.imageUrl,
      parentPassword: currentStudent.parentPassword,
      quizMarks: type == 'Quizzes' ? newMarks : currentStudent.quizMarks,
      assignmentMarks: type == 'Assignments' ? newMarks : currentStudent.assignmentMarks,
      midTermMarks: type == 'Mid-term' ? newMarks : currentStudent.midTermMarks,
      finalTermMarks: type == 'Final-term' ? newMarks : currentStudent.finalTermMarks,
      createdAt: currentStudent.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _studentApi.updateStudent(updatedStudent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  void _showEditor(StudentModel currentStudent, String type, Map<String, dynamic> currentData) {
    final Map<String, dynamic> tempMarks = Map.from(currentData);
    final keyController = TextEditingController();
    final valController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Manage $type', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextField(controller: keyController, decoration: InputDecoration(hintText: type == 'Assignments' ? 'Assignment Name' : 'Subject/Topic'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: valController, decoration: const InputDecoration(hintText: 'Marks/Grade'))),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () {
                      if (keyController.text.isNotEmpty && valController.text.isNotEmpty) {
                        setModalState(() => tempMarks[keyController.text] = valController.text);
                        keyController.clear();
                        valController.clear();
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: tempMarks.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final key = tempMarks.keys.elementAt(index);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tempMarks[key].toString(), style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () {
                              keyController.text = key;
                              valController.text = tempMarks[key].toString();
                              setModalState(() => tempMarks.remove(key));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => setModalState(() => tempMarks.remove(key)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _updateMarks(currentStudent, type, tempMarks);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save All Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentModel?>(
      stream: _studentApi.streamStudentById(widget.student.id),
      builder: (context, snapshot) {
        final student = snapshot.data ?? widget.student;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(student),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(student),
                      const SizedBox(height: 24),
                      _buildProfileHeader(student),
                      const SizedBox(height: 24),
                      _buildAttendanceSection(student),
                      const SizedBox(height: 24),
                      _buildDetailedInfo(student),
                      const SizedBox(height: 32),
                      const Text('Academic Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Select a card below to manage academic records.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildManagementCard(student, 'Quizzes', Icons.quiz, Colors.blue, student.quizMarks),
                          _buildManagementCard(student, 'Assignments', Icons.assignment, Colors.green, student.assignmentMarks),
                          _buildManagementCard(student, 'Mid-term', Icons.analytics, Colors.orange, student.midTermMarks),
                          _buildManagementCard(student, 'Final-term', Icons.workspace_premium, Colors.purple, student.finalTermMarks),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildAcademicSummary(student),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: (_userRole == 'teacher' || _userRole == 'school' || _userRole == 'head_teacher') 
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageStudentScreen(student: student)),
                  );
                },
                label: const Text('Edit Basic Info'),
                icon: const Icon(Icons.edit),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              )
            : null,
        );
      }
    );
  }

  Widget _buildAttendanceSection(StudentModel student) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendanceService.getStudentAttendance(student.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        int present = records.where((r) => r.status == 'present').length;
        int absent = records.where((r) => r.status == 'absent').length;
        int total = records.length;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                   Icon(Icons.bar_chart, color: AppColors.primary),
                   SizedBox(width: 8),
                   Text('Attendance Graph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CustomPaint(
                      painter: AttendanceChartPainter(
                        present: present.toDouble(),
                        absent: absent.toDouble(),
                        total: total == 0 ? 1 : total.toDouble(),
                        isEmpty: total == 0,
                      ),
                      child: Center(
                        child: Text(
                          total == 0 ? "0%" : "${(present / total * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatLite('Present', present.toString(), Colors.green),
                        const SizedBox(height: 8),
                        _buildStatLite('Absent', absent.toString(), Colors.red),
                        const SizedBox(height: 8),
                        _buildStatLite('Total Days', total.toString(), Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatLite(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSliverAppBar(StudentModel student) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(student.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
      ),
    );
  }

  Widget _buildProfileHeader(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: student.imageUrl.isNotEmpty ? NetworkImage(student.imageUrl) : null,
            child: student.imageUrl.isEmpty 
              ? Text(student.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
              : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Roll No: ${student.rollNo}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Class ${student.classId}-${student.section}', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                if (_userRole == 'teacher' || _userRole == 'head_teacher') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (student.email.isNotEmpty)
                        IconButton.filled(
                          onPressed: () => _messageUser(context, student.email, student.name, 'Student'),
                          icon: const Icon(Icons.message, size: 18),
                          tooltip: 'Message Student',
                          style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        ),
                      if (student.email.isNotEmpty) const SizedBox(width: 8),
                      if (student.parentEmail.isNotEmpty)
                        IconButton.filled(
                          onPressed: () => _messageUser(context, student.parentEmail, '${student.fatherName} (Parent)', 'Parent'),
                          icon: const Icon(Icons.family_restroom, size: 18),
                          tooltip: 'Message Parent',
                          style: IconButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detailed Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person_outline, 'Father Name', student.fatherName),
          const Divider(height: 32),
          _buildInfoRow(Icons.phone_android, 'Phone', student.phone),
          const Divider(height: 32),
          _buildInfoRow(Icons.email_outlined, 'Parent Email', student.parentEmail),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Address', student.address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value.isNotEmpty ? value : 'Not provided', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicSummary(StudentModel student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Academic Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _buildSummaryCard('Quizzes', student.quizMarks, Colors.blue),
        const SizedBox(height: 16),
        _buildSummaryCard('Assignments', student.assignmentMarks, Colors.green),
        const SizedBox(height: 16),
        _buildSummaryCard('Mid-term Exams', student.midTermMarks, Colors.orange),
        const SizedBox(height: 16),
        _buildSummaryCard('Final-term Exams', student.finalTermMarks, Colors.purple),
      ],
    );
  }

  Widget _buildSummaryCard(String title, Map<String, dynamic> marks, Color color) {
    if (marks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Text('${marks.length} Subjects', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Divider(height: 24),
          ...marks.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildManagementCard(StudentModel student, String title, IconData icon, Color color, Map<String, dynamic> data) {
    bool canEdit = _userRole == 'teacher' || _userRole == 'school' || _userRole == 'head_teacher';
    
    return InkWell(
      onTap: canEdit ? () => _showEditor(student, title, data) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('${data.length} Records', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Message Action Helper
  void _messageUser(BuildContext context, String email, String name, String userType) async {
    final chatService = ChatService();
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Finding $userType account...'), duration: const Duration(seconds: 1)));
    
    final uid = await chatService.getUserIdByEmail(email);
    
    if (uid != null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: uid,
              otherUserName: name,
              otherUserImage: '', // Can be fetched if needed
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userType account not found for email: $email')));
      }
    }
  }
}
