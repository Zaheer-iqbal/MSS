class StudentModel {
  final String id;
  final String name;
  final String rollNo;
  final String classId;
  final String section;
  final String email; // Student's own email for login linkage
  final String parentEmail;
  final String parentPassword;
  final Map<String, dynamic> quizMarks; // { 'Quiz Name': 85 }
  final Map<String, dynamic> assignmentMarks; // { 'Assignment 1': 'A' }
  final Map<String, dynamic> midTermMarks; // { 'Math': 75 }
  final Map<String, dynamic> finalTermMarks; // { 'Math': 88 }
  final String fatherName;
  final String phone;
  final String address;
  final String imageUrl;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.classId,
    required this.section,
    this.email = '', // Default empty
    required this.parentEmail,
    this.parentPassword = '', // Default to empty string for existing records
    this.quizMarks = const {},
    this.assignmentMarks = const {},
    this.midTermMarks = const {},
    this.finalTermMarks = const {},
    this.fatherName = '',
    this.phone = '',
    this.address = '',
    this.imageUrl = '',
    this.remarks = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'classId': classId,
      'section': section,
      'email': email,
      'parentEmail': parentEmail,
      'parentPassword': parentPassword,
      'quizMarks': quizMarks,
      'assignmentMarks': assignmentMarks,
      'midTermMarks': midTermMarks,
      'finalTermMarks': finalTermMarks,
      'fatherName': fatherName,
      'phone': phone,
      'address': address,
      'imageUrl': imageUrl,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, String docId) {
    return StudentModel(
      id: docId,
      name: map['name'] ?? '',
      rollNo: map['rollNo'] ?? '',
      classId: map['classId'] ?? '',
      section: map['section'] ?? '',
      email: map['email'] ?? '',
      parentEmail: map['parentEmail'] ?? '',
      parentPassword: map['parentPassword'] ?? '',
      quizMarks:
          (map['quizMarks'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          {},
      assignmentMarks:
          (map['assignmentMarks'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          {},
      midTermMarks:
          (map['midTermMarks'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          {},
      finalTermMarks:
          (map['finalTermMarks'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          {},
      fatherName: map['fatherName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      remarks: map['remarks'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ??
            map['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  StudentModel copyWith({
    String? name,
    String? rollNo,
    String? classId,
    String? section,
    String? email,
    String? parentEmail,
    String? parentPassword,
    Map<String, dynamic>? quizMarks,
    Map<String, dynamic>? assignmentMarks,
    Map<String, dynamic>? midTermMarks,
    Map<String, dynamic>? finalTermMarks,
    String? fatherName,
    String? phone,
    String? address,
    String? imageUrl,
    String? remarks,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      rollNo: rollNo ?? this.rollNo,
      classId: classId ?? this.classId,
      section: section ?? this.section,
      email: email ?? this.email,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPassword: parentPassword ?? this.parentPassword,
      quizMarks: quizMarks ?? this.quizMarks,
      assignmentMarks: assignmentMarks ?? this.assignmentMarks,
      midTermMarks: midTermMarks ?? this.midTermMarks,
      finalTermMarks: finalTermMarks ?? this.finalTermMarks,
      fatherName: fatherName ?? this.fatherName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
