import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _projectId = 'mss-dc20b';
  static const String _baseUrl = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  static const List<String> _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: iOS settings would go here
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Frontend message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel', // channelId
          'High Importance Notifications', // channelName
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'No Title',
      body: message.notification?.body ?? 'No Body',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Auto-subscribe to fundamental topics
      await _firebaseMessaging.subscribeToTopic('all');
    }
    return token;
  }

  // Subscribe user to specific role-based topics
  Future<void> subscribeToRoleTopics(String role) async {
    await _firebaseMessaging.subscribeToTopic('all_$role');
  }

  // Send notification to a specific user by UID (or studentId for parents)
  Future<void> sendNotification({
    required String targetId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Queue in Firestore for Backend processing (Industry Standard)
      await _firestore.collection('notifications').add({
        'targetId': targetId,
        'title': title,
        'body': body,
        'data': data,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Fetch Target User's Token and send DIRECTLY (Free Method)
      final userDoc = await _firestore.collection('users').doc(targetId).get();
      if (userDoc.exists) {
        final token = userDoc.data()?['fcmToken'];
        if (token != null) {
          await _sendFCMV1Request(
            targetToken: token,
            title: title,
            body: body,
            data: data,
          );
        }
      }
    } catch (e) {
      // Log error internally or use a logger
    }
  }

  // Get parent's UID (which is studentId) from Firestore
  Future<void> notifyParent({
    required String studentId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotification(
      targetId: studentId, // Parent UID is the studentId in our system
      title: title,
      body: body,
      data: data,
    );
  }

  // Send notification to a topic (e.g., 'all', 'all_parents', 'all_teachers')
  Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Queue in Firestore
      await _firestore.collection('notifications').add({
        'topic': topic,
        'title': title,
        'body': body,
        'data': data,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Send DIRECTLY via Topic (Free Method)
      await _sendFCMV1Request(
        topic: topic,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      // Internal error tracking
    }
  }

  // --- PRIVATE HELPERS FOR FCM V1 ---

  Future<String> _getAccessToken() async {
    final serviceAccountContent = await rootBundle.loadString('service-account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountContent);
    final client = await clientViaServiceAccount(accountCredentials, _scopes);
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  Future<void> _sendFCMV1Request({
    String? targetToken,
    String? topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final String accessToken = await _getAccessToken();

      final Map<String, dynamic> message = {
        'message': {
          if (targetToken != null) 'token': targetToken,
          if (topic != null) 'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          if (data != null) 'data': data.map((key, value) => MapEntry(key, value.toString())),
        }
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode != 200) {
        // print('FCM Error: ${response.body}');
      }
    } catch (e) {
      // print('Error sending direct FCM: $e');
    }
  }
}
