import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../student/services/student_api.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../teacher/services/teacher_api.dart';

class ManageStudentScreen extends StatefulWidget {
  final StudentModel? student;
  const ManageStudentScreen({super.key, this.student});

  @override
  State<ManageStudentScreen> createState() => _ManageStudentScreenState();
}

class _ManageStudentScreenState extends State<ManageStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentApi = StudentApi();
  
  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _classController;
  late TextEditingController _sectionController;
  late TextEditingController _parentEmailController;
  late TextEditingController _parentPasswordController;
  late TextEditingController _fatherNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name);
    _rollNoController = TextEditingController(text: widget.student?.rollNo);
    _classController = TextEditingController(text: widget.student?.classId);
    _sectionController = TextEditingController(text: widget.student?.section);
    _parentEmailController = TextEditingController(text: widget.student?.parentEmail);
    _parentPasswordController = TextEditingController(text: widget.student?.parentPassword);
    _fatherNameController = TextEditingController(text: widget.student?.fatherName);
    _phoneController = TextEditingController(text: widget.student?.phone);
    _addressController = TextEditingController(text: widget.student?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final student = StudentModel(
        id: widget.student?.id ?? '',
        name: _nameController.text.trim(),
        rollNo: _rollNoController.text.trim(),
        classId: _classController.text.trim(),
        section: _sectionController.text.trim(),
        parentEmail: _parentEmailController.text.trim(),
        parentPassword: _parentPasswordController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        imageUrl: widget.student?.imageUrl ?? '',
        quizMarks: widget.student?.quizMarks ?? {},
        assignmentMarks: widget.student?.assignmentMarks ?? {},
        midTermMarks: widget.student?.midTermMarks ?? {},
        finalTermMarks: widget.student?.finalTermMarks ?? {},
        createdAt: widget.student?.createdAt ?? DateTime.now(),
      );

      try {
        if (widget.student == null) {
          await _studentApi.addStudent(student);
        } else {
          await _studentApi.updateStudent(student);
        }

        // --- NEW LOGIC: Update Teacher's Class List ---
        if (mounted) {
           final authService = Provider.of<AuthService>(context, listen: false);
           final user = authService.currentUser;
           
           if (user != null) {
             final newClassId = _classController.text.trim();
             final newSection = _sectionController.text.trim();
             
             // Check if class exists
             final exists = user.assignedClasses.any((c) => 
               c['classId'] == newClassId && c['section'] == newSection
             );

             if (!exists) {
               // Create updated class list
               final updatedClasses = List<Map<String, String>>.from(user.assignedClasses);
               updatedClasses.add({
                 'classId': newClassId,
                 'section': newSection
               });

               // Create updated user
               final updatedUser = UserModel(
                 uid: user.uid,
                 email: user.email,
                 name: user.name,
                 role: user.role,
                 createdAt: user.createdAt,
                 imageUrl: user.imageUrl,
                 assignedClasses: updatedClasses,
                 schedule: user.schedule,
                 phone: user.phone,
                 address: user.address,
               );
               
               // Save to Firestore
               await TeacherApi().updateTeacherProfile(updatedUser);
               
               // Refresh local auth state to update Dashboard
               await authService.refreshUser();
             }
           }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student enrolled successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.student == null ? 'Enroll Student' : 'Edit Enrollment'),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enrollment Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the basic information to enroll the student in the system.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildTextField(_nameController, 'Full Name', Icons.person),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_rollNoController, 'Roll No', Icons.numbers)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_classController, 'Class', Icons.class_)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_sectionController, 'Section', Icons.grid_view)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_parentEmailController, 'Parent Email', Icons.email, keyboardType: TextInputType.emailAddress)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_parentPasswordController, 'Parent Password (Official)', Icons.lock_outline),
              const SizedBox(height: 16),
              _buildTextField(_fatherNameController, 'Father Name', Icons.person_outline),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_addressController, 'Address', Icons.location_on)),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_isLoading ? 'Processing...' : (widget.student == null ? 'Complete Enrollment' : 'Update Details')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}
