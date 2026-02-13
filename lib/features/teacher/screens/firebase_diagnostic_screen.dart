import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDiagnosticScreen extends StatefulWidget {
  const FirebaseDiagnosticScreen({super.key});

  @override
  State<FirebaseDiagnosticScreen> createState() =>
      _FirebaseDiagnosticScreenState();
}

class _FirebaseDiagnosticScreenState extends State<FirebaseDiagnosticScreen> {
  String _status = 'Idle';
  String _projectId = 'Loading...';
  String _authStatus = 'Checking...';
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _checkAppConfig();
  }

  Future<void> _checkAppConfig() async {
    try {
      final app = Firebase.app();
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _projectId = app.options.projectId;
        _authStatus = user != null
            ? 'Logged in as ${user.email} (${user.uid})'
            : 'Not Logged In';
      });
    } catch (e) {
      setState(() {
        _projectId = 'Error getting config: $e';
      });
    }
  }

  Future<void> _testWrite() async {
    setState(() {
      _status = 'Testing Write...';
      _statusColor = Colors.blue;
    });

    try {
      final testRef = FirebaseFirestore.instance
          .collection('diagnostic')
          .doc('test_doc');
      await testRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test_msg': 'Hello from diagnostic',
        'device_time': DateTime.now().toString(),
      });

      setState(() {
        _status = 'Write SUCCESS! Rules are working.';
        _statusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _status = 'Write FAILED: $e';
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _testRead() async {
    setState(() {
      _status = 'Testing Read...';
      _statusColor = Colors.blue;
    });

    try {
      final testRef = FirebaseFirestore.instance
          .collection('diagnostic')
          .doc('test_doc');
      final snapshot = await testRef.get();

      setState(() {
        if (snapshot.exists) {
          _status = 'Read SUCCESS! Data: ${snapshot.data()}';
        } else {
          _status = 'Read SUCCESS! (Doc does not exist, but access allowed)';
        }
        _statusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _status = 'Read FAILED: $e';
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Diagnostic')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'App Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Project ID: $_projectId'),
            Text('Auth Status: $_authStatus'),
            const Divider(height: 30),

            const Text(
              'Diagnostic Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Test Write Permission'),
              onPressed: _testWrite,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('Test Read Permission'),
              onPressed: _testRead,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              color: _statusColor.withOpacity(0.1),
              child: Text(
                'Result: $_status',
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
