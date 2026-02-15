class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'school', 'teacher', 'head_teacher', 'parent'
  final DateTime createdAt;
  final String imageUrl;
  final List<Map<String, String>>
  assignedClasses; // [{'classId': '1', 'section': 'A'}, ...]
  final List<Map<String, String>>
  schedule; // [{'day': 'Monday', 'time': '09:00 AM', 'classId': '1', 'section': 'A', 'subject': 'Math'}]
  final String phone;
  final String address;
  final String? fcmToken;
  final String schoolName;
  final String schoolNumber;
  final DateTime? assignedDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.imageUrl = '',
    this.assignedClasses = const [],
    this.schedule = const [],
    this.phone = '',
    this.address = '',
    this.fcmToken,
    this.schoolName = '',
    this.schoolNumber = '',
    this.assignedDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'assignedClasses': assignedClasses,
      'schedule': schedule,
      'phone': phone,
      'address': address,
      'fcmToken': fcmToken,
      'schoolName': schoolName,
      'schoolNumber': schoolNumber,
      'assignedDate': assignedDate?.toIso8601String(),
    };
  }

  // Create from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'parent',
      createdAt: DateTime.parse(map['createdAt']),
      assignedClasses: List<Map<String, String>>.from(
        (map['assignedClasses'] ?? []).map(
          (item) => Map<String, String>.from(item),
        ),
      ),
      schedule: List<Map<String, String>>.from(
        (map['schedule'] ?? []).map((item) => Map<String, String>.from(item)),
      ),
      imageUrl: map['imageUrl'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      fcmToken: map['fcmToken'],
      schoolName: map['schoolName'] ?? '',
      schoolNumber: map['schoolNumber'] ?? '',
      assignedDate: map['assignedDate'] != null
          ? DateTime.parse(map['assignedDate'])
          : null,
    );
  }
}
