import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../teacher/services/teacher_api.dart';
import '../../../../core/models/teacher_attendance_model.dart';
import '../../../../core/services/teacher_attendance_service.dart';
import '../../teacher/screens/attendance_summary_screen.dart'; // For AttendanceChartPainter

class ManageTeacherProfileScreen extends StatefulWidget {
  final UserModel teacher;
  const ManageTeacherProfileScreen({super.key, required this.teacher});

  @override
  State<ManageTeacherProfileScreen> createState() => _ManageTeacherProfileScreenState();
}

class _ManageTeacherProfileScreenState extends State<ManageTeacherProfileScreen> {
  final _teacherApi = TeacherApi();
  final _attendanceService = TeacherAttendanceService();
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late List<Map<String, String>> _schedule;
  late List<Map<String, String>> _assignedClasses;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher.name);
    _imageUrlController = TextEditingController(text: widget.teacher.imageUrl);
    _schedule = List<Map<String, String>>.from(widget.teacher.schedule.map((e) => Map<String, String>.from(e)));
    _assignedClasses = List<Map<String, String>>.from(widget.teacher.assignedClasses.map((e) => Map<String, String>.from(e)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    String imageUrl = _imageUrlController.text.trim();

    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      imageUrl = base64Encode(bytes);
    }

    final updatedTeacher = UserModel(
      uid: widget.teacher.uid,
      email: widget.teacher.email,
      name: _nameController.text.trim(),
      role: widget.teacher.role,
      createdAt: widget.teacher.createdAt,
      assignedClasses: _assignedClasses,
      imageUrl: imageUrl,
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
    String? selectedDay;
    String? selectedClass;
    String? selectedSection;
    String? selectedSubject;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> classes = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    final List<String> sections = ['A', 'B', 'C', 'D'];
    final List<String> subjects = [
      'Mathematics',
      'English',
      'Science',
      'History',
      'Geography',
      'Computer Science',
      'Art',
      'Physical Education',
      'Urdu',
      'Islamiyat'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text('Add Schedule Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Day Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (val) => setSheetState(() => selectedDay = val),
                  ),
                  const SizedBox(height: 16),

                  // Time Range Picker
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                            if (time != null) setSheetState(() => startTime = time);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(startTime?.format(context) ?? 'Start Time', style: TextStyle(color: startTime != null ? Colors.black : Colors.grey[600])),
                                const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
                            if (time != null) setSheetState(() => endTime = time);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(endTime?.format(context) ?? 'End Time', style: TextStyle(color: endTime != null ? Colors.black : Colors.grey[600])),
                                const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Class & Section Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedClass,
                          decoration: InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setSheetState(() => selectedClass = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedSection,
                          decoration: InputDecoration(
                            labelText: 'Sec',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setSheetState(() => selectedSection = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subject Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubject,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setSheetState(() => selectedSubject = val),
                  ),
                  const SizedBox(height: 32),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedDay != null && startTime != null && endTime != null && selectedClass != null && selectedSection != null && selectedSubject != null) {
                          final timeString = '${startTime!.format(context)} - ${endTime!.format(context)}';
                          setState(() {
                            _schedule.add({
                              'day': selectedDay!,
                              'time': timeString,
                              'classId': selectedClass!,
                              'section': selectedSection!,
                              'subject': selectedSubject!,
                            });
                          });
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add to Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addAssignedClass() {
    final classController = TextEditingController();
    final sectionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign New Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class (e.g. 1st, 2nd, 3rd)')),
            TextField(controller: sectionController, decoration: const InputDecoration(labelText: 'Section (e.g. A, B, C)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (classController.text.isNotEmpty && sectionController.text.isNotEmpty) {
                setState(() {
                  _assignedClasses.add({
                    'classId': classController.text.trim(),
                    'section': sectionController.text.trim(),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Assign'),
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
            _buildAttendanceSection(),
            const SizedBox(height: 32),
            _buildAssignedClassesSection(),
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
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_imageUrlController.text.isNotEmpty
                          ? (_imageUrlController.text.startsWith('http') 
                              ? NetworkImage(_imageUrlController.text) 
                              : MemoryImage(base64Decode(_imageUrlController.text)))
                          : null) as ImageProvider?,
                  child: (_imageFile == null && _imageUrlController.text.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 25);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Widget _buildAttendanceSection() {
    return StreamBuilder<List<TeacherAttendanceModel>>(
      stream: _attendanceService.getTeacherAttendance(widget.teacher.uid),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                   Icon(Icons.bar_chart, color: AppColors.primary),
                   SizedBox(width: 8),
                   Text('Attendance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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


  Widget _buildAssignedClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assigned Classes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            IconButton.filled(onPressed: _addAssignedClass, icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 16),
        if (_assignedClasses.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No classes assigned')))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _assignedClasses.length,
            itemBuilder: (context, index) {
              final item = _assignedClasses[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Class ${item['classId']}-${item['section']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _assignedClasses.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
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
