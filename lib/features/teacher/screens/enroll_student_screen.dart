import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../student/services/student_api.dart';

class EnrollStudentScreen extends StatefulWidget {
  const EnrollStudentScreen({super.key});

  @override
  State<EnrollStudentScreen> createState() => _EnrollStudentScreenState();
}

class _EnrollStudentScreenState extends State<EnrollStudentScreen> {
  int _currentStep = 0;
  final _studentApi = StudentApi();
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Controllers for Step 1: Personal
  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  File? _selectedImage;

  // Controllers for Step 2: Academic
  String? _selectedClass;
  String? _selectedSection;
  final _rollNoController = TextEditingController();

  // Controllers for Step 3: Guardian
  final _parentNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _relationshipController.text = 'Father';
    
    // Auto-generation logic for Parent Credentials (as a default)
    void updateCredentials() {
      if (_nameController.text.isNotEmpty && _rollNoController.text.isNotEmpty) {
        final nameSnippet = _nameController.text.split(' ').first.toLowerCase();
        _parentEmailController.text = '${nameSnippet}_${_rollNoController.text}@school.com';
        _parentPasswordController.text = 'pass${_rollNoController.text}';
      }
    }

    _nameController.addListener(updateCredentials);
    _rollNoController.addListener(updateCredentials);

    // Initial check for assigned classes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null && user.assignedClasses.isNotEmpty) {
        if (user.assignedClasses.length == 1) {
          setState(() {
            _selectedClass = user.assignedClasses[0]['classId'];
            _selectedSection = user.assignedClasses[0]['section'];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _parentNameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // Use low quality to keep Base64 string small for Firestore headers/limits
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 25);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitEnrollment();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitEnrollment() async {
    if (_nameController.text.isEmpty || _rollNoController.text.isEmpty || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String imageUrl = '';
      // 1. Convert to Base64 (No Firebase Storage)
      if (_selectedImage == null) {
        throw 'Please select a student photo';
      }

      final bytes = await _selectedImage!.readAsBytes();
      imageUrl = base64Encode(bytes);

      final student = StudentModel(
        id: '', 
        name: _nameController.text.trim(),
        rollNo: _rollNoController.text.trim(),
        classId: _selectedClass!,
        section: _selectedSection ?? 'A',
        email: '',
        parentEmail: _parentEmailController.text.trim(),
        parentPassword: _parentPasswordController.text.trim(),
        fatherName: _parentNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        imageUrl: imageUrl,
        quizMarks: {},
        assignmentMarks: {},
        midTermMarks: {},
        finalTermMarks: {},
        remarks: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _studentApi.addStudent(student);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student enrolled successfully!'), backgroundColor: Colors.green),
        );
        _resetForm();
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

  void _resetForm() {
     setState(() {
       _currentStep = 0;
       _nameController.clear();
       _rollNoController.clear();
       _parentNameController.clear();
       _phoneController.clear();
       _addressController.clear();
       _parentEmailController.clear();
       _parentPasswordController.clear();
       _selectedClass = null;
       _selectedSection = null;
       _selectedImage = null;
       _dob = null;
       _gender = null;
     });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Student', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(onPressed: _resetForm, child: const Text('Reset', style: TextStyle(color: Colors.blue))),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: (Provider.of<AuthService>(context).currentUser?.assignedClasses.isEmpty ?? true)
                  ? _buildNoClassesView()
                  : _buildCurrentStepView(),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildNoClassesView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.lock_person_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 24),
        const Text(
          'No Classes Assigned',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        const Text(
          'You can only enroll students in classes assigned to you by the Head Teacher. Please contact your Head Teacher to get classes assigned.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (Provider.of<AuthService>(context).currentUser?.assignedClasses.isEmpty ?? true) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          _buildProgressCircle(0, 'Personal'),
          Expanded(child: Container(height: 2, color: _currentStep > 0 ? Colors.blue : Colors.grey.shade200)),
          _buildProgressCircle(1, 'Academic'),
          Expanded(child: Container(height: 2, color: _currentStep > 1 ? Colors.blue : Colors.grey.shade200)),
          _buildProgressCircle(2, 'Guardian'),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(int step, String label) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.blue : (isActive ? Colors.white : Colors.grey.shade100),
            border: Border.all(color: isActive || isCompleted ? Colors.blue : Colors.grey.shade300, width: 2),
            boxShadow: isActive ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 10)] : null,
          ),
          child: Center(
            child: isCompleted 
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('${step + 1}', style: TextStyle(color: isActive ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive || isCompleted ? Colors.blue : Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0: return _buildPersonalStep();
      case 1: return _buildAcademicStep();
      case 2: return _buildGuardianStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceOptions(),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Icon(Icons.add_a_photo_outlined, color: Colors.blue, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Click to Take/Upload Photo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildInputField(label: 'Full Name', hint: 'e.g. John Doe', controller: _nameController),
        const SizedBox(height: 20),
        _buildDatePickerField(label: 'Date of Birth', value: _dob),
        const SizedBox(height: 20),
        const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildGenderChip('Male'),
            const SizedBox(width: 12),
            _buildGenderChip('Female'),
            const SizedBox(width: 12),
            _buildGenderChip('Other'),
          ],
        ),
      ],
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStep() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final List<Map<String, String>> assigned = user?.assignedClasses ?? [];

    // If teacher has assigned classes, limit the options
    final List<String> classOptions = assigned.isNotEmpty 
        ? assigned.map((e) => e['classId']!).toSet().toList()
        : ['1st', '2nd', '3rd', '4th', '5th'];

    final List<String> sectionOptions = assigned.isNotEmpty
        ? assigned.where((e) => e['classId'] == _selectedClass).map((e) => e['section']!).toSet().toList()
        : ['A', 'B', 'C'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Academic Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Configure class enrollment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'GRADE / CLASS', 
                value: _selectedClass, 
                items: classOptions, 
                onChanged: (v) {
                  setState(() {
                    _selectedClass = v;
                    _selectedSection = null; // Reset section when class changes
                    
                    // If the newly selected class has only one section assigned, auto-select it
                    if (assigned.isNotEmpty) {
                      final availableSections = assigned.where((e) => e['classId'] == v).toList();
                      if (availableSections.length == 1) {
                        _selectedSection = availableSections[0]['section'];
                      }
                    }
                  });
                }
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'SECTION', 
                value: _selectedSection, 
                items: sectionOptions, 
                onChanged: (v) => setState(() => _selectedSection = v)
              )
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildInputField(label: 'ROLL NUMBER', hint: 'e.g. 2045', controller: _rollNoController),
      ],
    );
  }

  Widget _buildGuardianStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Guardian Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Finalize the contact and login details.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 32),
        _buildInputField(label: 'Guardian Full Name', hint: 'e.g. Jane Doe', controller: _parentNameController, icon: Icons.person_outline),
        const SizedBox(height: 20),
        _buildInputField(label: 'Relationship', hint: 'Father, Mother, etc.', controller: _relationshipController, icon: Icons.people_outline),
        const SizedBox(height: 20),
        _buildInputField(label: 'Phone Number', hint: '+1 (555) 000-0000', controller: _phoneController, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
        const SizedBox(height: 20),
        
        const Text('PARENT LOGIN CREDENTIALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _buildInputField(label: 'Parent Email', hint: 'email@example.com', controller: _parentEmailController, icon: Icons.alternate_email),
        const SizedBox(height: 16),
        _buildInputField(label: 'Parent Password', hint: 'min 6 characters', controller: _parentPasswordController, icon: Icons.lock_outline),
        
        const SizedBox(height: 24),
        _buildInputField(label: 'Residential Address', hint: '123 Education Lane...', controller: _addressController, icon: Icons.location_on_outlined, maxLines: 2),
      ],
    );
  }

  Widget _buildInputField({required String label, required String hint, required TextEditingController controller, IconData? icon, TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: icon != null ? 0 : 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey.shade400) : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({required String label, DateTime? value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime(2015), firstDate: DateTime(2000), lastDate: DateTime.now());
            if (date != null) setState(() => _dob = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value == null ? 'MM/DD/YYYY' : DateFormat('MM/dd/yyyy').format(value), style: TextStyle(color: value == null ? Colors.grey.shade400 : Colors.black, fontSize: 14)),
                Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text('Select', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String label) {
    bool isSelected = _gender == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 10)] : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (Provider.of<AuthService>(context).currentUser?.assignedClasses.isEmpty ?? true) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Uploading...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )
                : Text(_currentStep == 2 ? 'Submit Student' : 'Next Step', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
