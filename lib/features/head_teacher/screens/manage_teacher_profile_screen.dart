import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../teacher/services/teacher_api.dart';

class ManageTeacherProfileScreen extends StatefulWidget {
  final UserModel teacher;
  const ManageTeacherProfileScreen({super.key, required this.teacher});

  @override
  State<ManageTeacherProfileScreen> createState() => _ManageTeacherProfileScreenState();
}

class _ManageTeacherProfileScreenState extends State<ManageTeacherProfileScreen> {
  final _teacherApi = TeacherApi();
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late List<Map<String, String>> _schedule;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher.name);
    _imageUrlController = TextEditingController(text: widget.teacher.imageUrl);
    _schedule = List.from(widget.teacher.schedule);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final updatedTeacher = UserModel(
      uid: widget.teacher.uid,
      email: widget.teacher.email,
      name: _nameController.text.trim(),
      role: widget.teacher.role,
      createdAt: widget.teacher.createdAt,
      assignedClasses: widget.teacher.assignedClasses,
      imageUrl: _imageUrlController.text.trim(),
      schedule: _schedule,
    );

    try {
      await _teacherApi.updateTeacherProfile(updatedTeacher);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addScheduleEntry() {
    final dayController = TextEditingController();
    final timeController = TextEditingController();
    final classController = TextEditingController();
    final sectionController = TextEditingController();
    final subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Day (e.g. Monday)')),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time (e.g. 09:00 AM)')),
              TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class')),
              TextField(controller: sectionController, decoration: const InputDecoration(labelText: 'Section')),
              TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (dayController.text.isNotEmpty && timeController.text.isNotEmpty) {
                setState(() {
                  _schedule.add({
                    'day': dayController.text.trim(),
                    'time': timeController.text.trim(),
                    'classId': classController.text.trim(),
                    'section': sectionController.text.trim(),
                    'subject': subjectController.text.trim(),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Teacher Profile'),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Class Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton.filled(onPressed: _addScheduleEntry, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 16),
            if (_schedule.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No schedule entries found')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedule.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = _schedule[index];
                  return _buildScheduleItem(index, entry);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 16),
          TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL', prefixIcon: Icon(Icons.image))),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(int index, Map<String, String> entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry['day']} - ${entry['time']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text('${entry['subject']} | Class ${entry['classId']}-${entry['section']}', style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
          IconButton(onPressed: () => setState(() => _schedule.removeAt(index)), icon: const Icon(Icons.delete, color: Colors.red)),
        ],
      ),
    );
  }
}
