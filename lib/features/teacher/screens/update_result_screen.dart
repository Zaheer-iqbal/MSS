import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../student/services/student_api.dart';
import '../../../core/services/notification_service.dart';

class UpdateResultScreen extends StatefulWidget {
  final StudentModel student;
  final String initialCategory;

  const UpdateResultScreen({
    super.key,
    required this.student,
    required this.initialCategory,
  });

  @override
  State<UpdateResultScreen> createState() => _UpdateResultScreenState();
}

class _UpdateResultScreenState extends State<UpdateResultScreen> {
  late String _selectedCategory;
  late TextEditingController _remarksController;
  final _studentApi = StudentApi();
  bool _isLoading = false;

  // Local copies of marks to edit
  late Map<String, dynamic> _quizMarks;
  late Map<String, dynamic> _assignmentMarks;
  late Map<String, dynamic> _midTermMarks;
  late Map<String, dynamic> _finalTermMarks;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _remarksController = TextEditingController(text: widget.student.remarks);

    // Initialize marks from student object
    _quizMarks = Map.from(widget.student.quizMarks);
    _assignmentMarks = Map.from(widget.student.assignmentMarks);
    _midTermMarks = Map.from(widget.student.midTermMarks);
    _finalTermMarks = Map.from(widget.student.finalTermMarks);
  }

  Map<String, dynamic> get _currentMarks {
    switch (_selectedCategory) {
      case 'Quizzes':
        return _quizMarks;
      case 'Assignments':
        return _assignmentMarks;
      case 'Mid-term':
        return _midTermMarks;
      case 'Final-term':
        return _finalTermMarks;
      default:
        return {};
    }
  }

  void _updateCurrentMark(String subject, String value) {
    setState(() {
      _currentMarks[subject] = value;
    });
  }

  Future<void> _saveResults() async {
    setState(() => _isLoading = true);
    try {
      final updatedStudent = widget.student.copyWith(
        quizMarks: _quizMarks,
        assignmentMarks: _assignmentMarks,
        midTermMarks: _midTermMarks,
        finalTermMarks: _finalTermMarks,
        remarks: _remarksController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _studentApi.updateStudent(updatedStudent);

      // Send notification to Parent
      await NotificationService().notifyParent(
        studentId: widget.student.id,
        title: 'Academic Update: $_selectedCategory',
        body: 'New marks have been uploaded for ${widget.student.name}. Please check the Parent Dashboard.',
        data: {
          'type': 'marks',
          'category': _selectedCategory,
          'studentId': widget.student.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results published successfully!'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.blue,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Update Result',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentInfo(),
            const SizedBox(height: 24),
            const Text(
              'SELECT EXAM / TERM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBJECT WISE PERFORMANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                _buildAddSubjectButton(),
              ],
            ),
            const SizedBox(height: 12),
            _buildSubjectList(),
            const SizedBox(height: 16),
            _buildGrandTotalSummary(),
            const SizedBox(height: 24),
            const Text(
              'TEACHER REMARKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            _buildRemarksSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Publishing will send an instant notification to parents',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.student.imageUrl.isNotEmpty
                ? NetworkImage(widget.student.imageUrl)
                : null,
            child: widget.student.imageUrl.isEmpty
                ? Text(widget.student.name[0])
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.badge,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${widget.student.rollNo}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.school,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Class ${widget.student.classId}-${widget.student.section}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Quizzes', 'Assignments', 'Mid-term', 'Final-term'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E3E8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_currentMarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              const Text(
                'No subjects added yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _currentMarks.length,
      itemBuilder: (context, index) {
        final subject = _currentMarks.keys.elementAt(index);
        final value = _currentMarks[subject].toString();
        return _buildSubjectCard(subject, value);
      },
    );
  }

  Widget _buildSubjectCard(String subject, String value) {
    // Attempt to parse marks to show Pass/Fail badge if they are numbers
    bool? isPass;
    try {
      final parts = value.split('/');
      if (parts.length == 2) {
        final obtained = double.parse(parts[0]);
        final total = double.parse(parts[1]);
        isPass = obtained >= (total * 0.4); // 40% passing
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isPass != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPass
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPass ? Icons.check_circle : Icons.error,
                        size: 12,
                        color: isPass ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPass ? 'PASS' : 'FAIL',
                        style: TextStyle(
                          color: isPass ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMarkInputSection('OBTAINED', value.split('/').first, (v) {
                final total = value.contains('/') ? value.split('/')[1] : '100';
                _updateCurrentMark(subject, '$v/$total');
              }),
              const SizedBox(width: 16),
              _buildMarkInputSection(
                'TOTAL',
                value.contains('/') ? value.split('/')[1] : '100',
                (v) {
                  final obtained = value.split('/').first;
                  _updateCurrentMark(subject, '$obtained/$v');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkInputSection(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE1E3E8)),
            ),
            child: TextField(
              onChanged: onChanged,
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 18,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E3E8)),
      ),
      child: TextField(
        controller: _remarksController,
        maxLines: 4,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Add summary of student performance...',
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveResults,
        icon: _isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.publish, size: 20),
        label: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save & Publish Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAddSubjectButton() {
    return TextButton.icon(
      onPressed: _showAddSubjectDialog,
      icon: const Icon(Icons.add, size: 16),
      label: const Text(
        'Add Subject',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(foregroundColor: Colors.blue),
    );
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Mathematics'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _currentMarks[controller.text] = '0/100');
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalSummary() {
    if (_currentMarks.isEmpty) return const SizedBox.shrink();

    double totalObtained = 0;
    double totalMax = 0;

    _currentMarks.forEach((_, value) {
      try {
        final parts = value.toString().split('/');
        if (parts.length == 2) {
          totalObtained += double.parse(parts[0]);
          totalMax += double.parse(parts[1]);
        } else {
          totalObtained += double.parse(value.toString());
          totalMax += 100;
        }
      } catch (_) {}
    });

    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
    final isPass = percentage >= 40;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              _buildStatusBadgeUi(isPass),
            ],
          ),
          Text(
            '${totalObtained.toStringAsFixed(0)}/${totalMax.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeUi(bool isPass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPass
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPass ? Icons.check_circle : Icons.error,
            size: 10,
            color: isPass ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isPass ? 'PASS' : 'FAIL',
            style: TextStyle(
              color: isPass ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
