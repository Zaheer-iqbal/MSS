import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../student/services/student_api.dart';
import 'manage_student_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentModel student;
  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late StudentModel _currentStudent;
  final _studentApi = StudentApi();

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
  }

  Future<void> _updateMarks(String type, Map<String, dynamic> newMarks) async {
    final updatedStudent = StudentModel(
      id: _currentStudent.id,
      name: _currentStudent.name,
      rollNo: _currentStudent.rollNo,
      classId: _currentStudent.classId,
      section: _currentStudent.section,
      parentEmail: _currentStudent.parentEmail,
      fatherName: _currentStudent.fatherName,
      phone: _currentStudent.phone,
      address: _currentStudent.address,
      imageUrl: _currentStudent.imageUrl,
      quizMarks: type == 'Quizzes' ? newMarks : _currentStudent.quizMarks,
      assignmentMarks: type == 'Assignments' ? newMarks : _currentStudent.assignmentMarks,
      midTermMarks: type == 'Mid-term' ? newMarks : _currentStudent.midTermMarks,
      finalTermMarks: type == 'Final-term' ? newMarks : _currentStudent.finalTermMarks,
      createdAt: _currentStudent.createdAt,
    );

    try {
      await _studentApi.updateStudent(updatedStudent);
      setState(() => _currentStudent = updatedStudent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  void _showEditor(String type, Map<String, dynamic> currentData) {
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                      title: Text(key),
                      trailing: Text(tempMarks[key].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onLongPress: () => setModalState(() => tempMarks.remove(key)),
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
                    _updateMarks(type, tempMarks);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildDetailedInfo(),
                  const SizedBox(height: 32),
                  const Text('Academic Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Select a card below to manage specific academic records for this student.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildManagementCard('Quizzes', Icons.quiz, Colors.blue, _currentStudent.quizMarks),
                      _buildManagementCard('Assignments', Icons.assignment, Colors.green, _currentStudent.assignmentMarks),
                      _buildManagementCard('Mid-term', Icons.analytics, Colors.orange, _currentStudent.midTermMarks),
                      _buildManagementCard('Final-term', Icons.workspace_premium, Colors.purple, _currentStudent.finalTermMarks),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageStudentScreen(student: _currentStudent)),
          );
          if (result != null && mounted) {
            // Re-fetch or update current student
            final updated = await _studentApi.getStudentById(_currentStudent.id);
            if (updated != null) setState(() => _currentStudent = updated);
          }
        },
        label: const Text('Edit Basic Info'),
        icon: const Icon(Icons.edit),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_currentStudent.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
      ),
    );
  }

  Widget _buildProfileHeader() {
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
            backgroundImage: _currentStudent.imageUrl.isNotEmpty ? NetworkImage(_currentStudent.imageUrl) : null,
            child: _currentStudent.imageUrl.isEmpty 
              ? Text(_currentStudent.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
              : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentStudent.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Roll No: ${_currentStudent.rollNo}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Class ${_currentStudent.classId}-${_currentStudent.section}', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
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
          _buildInfoRow(Icons.person_outline, 'Father Name', _currentStudent.fatherName),
          const Divider(height: 32),
          _buildInfoRow(Icons.phone_android, 'Phone', _currentStudent.phone),
          const Divider(height: 32),
          _buildInfoRow(Icons.email_outlined, 'Parent Email', _currentStudent.parentEmail),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Address', _currentStudent.address),
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

  Widget _buildManagementCard(String title, IconData icon, Color color, Map<String, dynamic> data) {
    return InkWell(
      onTap: () => _showEditor(title, data),
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
}
