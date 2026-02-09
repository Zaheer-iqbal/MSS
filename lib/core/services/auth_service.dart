import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _currentUser = null;
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
  }) async {
    try {
      // 1. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Sync name with Firebase Auth profile
        await user.updateDisplayName(name);
        
        // 2. Create User Model
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        // 3. Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        
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
  Future<String?> login({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Fetch user data including role
        return await _fetchUserData(result.user!.uid);
      }
      return "Login failed";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Login for Parents (Restricted Access)
  StudentModel? _currentStudent;
  StudentModel? get currentStudent => _currentStudent;

  Future<StudentModel?> loginParent({required String email, required String password}) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('parentEmail', isEqualTo: email)
          .where('parentPassword', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final student = StudentModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
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
      return null;
    } catch (e) {
      print("Parent Login Error: $e");
      return null;
    }
  }

  // Fetch User Data from Firestore
  Future<String?> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        _isInitializing = false;
        notifyListeners();
        return null; // Success
      } else {
        _isInitializing = false;
        notifyListeners();
        return "User data not found";
      }
    } catch (e) {
      _isInitializing = false;
      notifyListeners();
      return e.toString();
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
