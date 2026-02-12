import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../student/services/student_api.dart';

class ManageStudentScreen extends StatefulWidget {
  final StudentModel? student;
  const ManageStudentScreen({super.key, this.student});

  @override
  State<ManageStudentScreen> createState() => _ManageStudentScreenState();
}

class _ManageStudentScreenState extends State<ManageStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentApi = StudentApi();
  final _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _classController;
  late TextEditingController _sectionController;
  late TextEditingController _parentEmailController;
  late TextEditingController _parentPasswordController;
  late TextEditingController _fatherNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  File? _selectedImage;
  String? _currentImageUrl;
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
    _currentImageUrl = widget.student?.imageUrl;
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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        String finalImageUrl = _currentImageUrl ?? '';

        // 1. Upload new image if selected
        if (_selectedImage != null) {
          final fileName = '${_rollNoController.text.replaceAll(RegExp(r'[^\w]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance
              .ref()
              .child('student_profiles')
              .child(fileName);
          
          final uploadTask = ref.putFile(
            _selectedImage!,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          final TaskSnapshot snapshot = await uploadTask;
          finalImageUrl = await snapshot.ref.getDownloadURL();
        }

        final student = StudentModel(
          id: widget.student?.id ?? '',
          name: _nameController.text.trim(),
          rollNo: _rollNoController.text.trim(),
          classId: _classController.text.trim(),
          section: _sectionController.text.trim(),
          email: widget.student?.email ?? '',
          parentEmail: _parentEmailController.text.trim(),
          parentPassword: _parentPasswordController.text.trim(),
          fatherName: _fatherNameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          imageUrl: finalImageUrl,
          quizMarks: widget.student?.quizMarks ?? {},
          assignmentMarks: widget.student?.assignmentMarks ?? {},
          midTermMarks: widget.student?.midTermMarks ?? {},
          finalTermMarks: widget.student?.finalTermMarks ?? {},
          remarks: widget.student?.remarks ?? '',
          createdAt: widget.student?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.student == null) {
          await _studentApi.addStudent(student);
        } else {
          await _studentApi.updateStudent(student);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details saved successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
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
              _buildImagePicker(),
              const SizedBox(height: 32),
              const Text(
                'Enrollment Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update the basic information for this student.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildTextField(_nameController, 'Full Name', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_fatherNameController, 'Father Name', Icons.person_outline),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_rollNoController, 'Roll No', Icons.numbers)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildClassDropdown()),
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
              _buildTextField(_parentPasswordController, 'Parent Password', Icons.lock_outline),
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

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                      ? (_currentImageUrl!.startsWith('http') 
                          ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
                          : Image.memory(base64Decode(_currentImageUrl!), fit: BoxFit.cover))
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, size: 60, color: AppColors.primary),
                        ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImageSourceOptions(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    final classes = ['1st', '2nd', '3rd', '4th', '5th'];
    if (_classController.text.isNotEmpty && !classes.contains(_classController.text)) {
      classes.add(_classController.text);
    }
    
    return DropdownButtonFormField<String>(
      initialValue: _classController.text.isEmpty ? null : _classController.text,
      decoration: InputDecoration(
        labelText: 'Class',
        prefixIcon: const Icon(Icons.class_, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (value) => setState(() => _classController.text = value ?? ''),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
