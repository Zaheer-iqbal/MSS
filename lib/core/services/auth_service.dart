import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper to save FCM Token
  Future<void> _saveDeviceToken(String uid) async {
    try {
      final notificationService = NotificationService();
      String? token = await notificationService.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
        });

        // Also subscribe to role-based topics
        if (_currentUser != null) {
          await notificationService.subscribeToRoleTopics(_currentUser!.role);
        }
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print("AuthService: User detected: ${user.uid}");
        _fetchUserData(user.uid);
      } else {
        print("AuthService: User signed out");
        _currentUser = null;
        // _isInitializing = false; // Don't set this to false here on logout, only initially?
        // Actually, on logout we are not initializing, we are just done.
        _isInitializing = false;
        notifyListeners();
      }
    });
  }

  // Sign Up with Email, Password, and Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String phone = '',
    String schoolName = '',
    String schoolNumber = '',
    DateTime? assignedDate,
    String? securityKey,
  }) async {
    try {
      // 1. Verification for Head Teacher
      if (role == 'head_teacher') {
        if (phone.length != 11) {
          return "Mobile number must be exactly 11 digits";
        }
        final lastFour = phone.substring(phone.length - 4);
        if (securityKey != lastFour) {
          return "Invalid Security Key. It must be the last 4 digits of your mobile number.";
        }
      }

      // 2. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Sync name with Firebase Auth profile
        await user.updateDisplayName(name);

        // 3. Create User Model
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
          phone: phone,
          schoolName: schoolName,
          schoolNumber: schoolNumber,
          assignedDate: assignedDate,
        );

        // 4. Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        await _saveDeviceToken(user.uid); // Save token

        _currentUser = newUser;
        notifyListeners();
        return null; // Success
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      print("AuthService: Attempting login for $email");
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("AuthService: Firebase Auth successful. UID: ${result.user?.uid}");

      if (result.user != null) {
        // Optimization: If listener already fetched data, return success
        if (_currentUser != null && _currentUser!.uid == result.user!.uid) {
          print("AuthService: User data already loaded. Skipping fetch.");
          return null;
        }

        // Fetch user data including role
        final error = await _fetchUserData(result.user!.uid);
        if (error == null) {
          await _saveDeviceToken(result.user!.uid);
        }
        return error;
      }
      return "Login failed";
    } on FirebaseAuthException catch (e) {
      print("AuthService: Login Error: ${e.message}");
      return e.message;
    } catch (e) {
      print("AuthService: Login Exception: $e");
      return e.toString();
    }
  }

  // Login for Parents (Restricted Access)
  StudentModel? _currentStudent;
  StudentModel? get currentStudent => _currentStudent;

  Future<StudentModel?> loginParent({
    required String email,
    required String password,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('parentEmail', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        // Verify password in memory to avoid needing a Firestore composite index
        if (data['parentPassword'] == password) {
          final student = StudentModel.fromMap(data, doc.id);
          _currentStudent = student;
          // Create a temporary user session for AuthWrapper
          _currentUser = UserModel(
            uid: student.id,
            email: email,
            name: "Parent of ${student.name.split(' ')[0]}",
            role: 'parent',
            createdAt: DateTime.now(),
          );
          notifyListeners();
          return student;
        }
      }
      return null;
    } catch (e) {
      print("Parent Login Error: $e");
      return null;
    }
  }

  // Fetch User Data from Firestore
  Future<String?> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);

        // If user is a student, try to fetch their academic record
        if (_currentUser!.role == 'student') {
          await _fetchStudentData(_currentUser!.email);
        }

        _isInitializing = false;
        notifyListeners();
        return null; // Success
      } else {
        _isInitializing = false;
        notifyListeners();
        return "User data not found";
      }
    } catch (e) {
      print("AuthService: Error fetching user data: $e");
      _isInitializing = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> _fetchStudentData(String email) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _currentStudent = StudentModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
    } catch (e) {
      print("Error fetching student data: $e");
    }
  }

  // Refresh User Data manually
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await _fetchUserData(_currentUser!.uid);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _currentStudent = null;
    notifyListeners();
  }
}
