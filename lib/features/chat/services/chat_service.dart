import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a consistent Chat ID for two users regardless of order
  String _getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); 
    return ids.join("_");
  }

  // Send Message
  Future<void> sendMessage(String senderId, String receiverId, String message, {String? senderRole}) async {
    try {
      final String chatId = _getChatId(senderId, receiverId);
      final DateTime timestamp = DateTime.now();

      final newMessage = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp,
        senderRole: senderRole,
      );

      // 1. Add to main messages collection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toMap());

      // 2. Update Sender's Chat List
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('my_chats')
          .doc(receiverId)
          .set({
            'chatId': chatId,
            'otherUserId': receiverId,
            'lastMessage': message,
            'timestamp': timestamp.toIso8601String(),
            'unreadCount': 0, // Sent by me, so 0 unread
          });

      // 3. Update Receiver's Chat List
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('my_chats')
          .doc(senderId)
          .set({
            'chatId': chatId,
            'otherUserId': senderId,
            'lastMessage': message,
            'timestamp': timestamp.toIso8601String(),
            'unreadCount': FieldValue.increment(1), // Increment unread for receiver
          }, SetOptions(merge: true));

    } catch (e) {
      if (kDebugMode) print("Error sending message: $e");
      rethrow;
    }
  }

  // Get Messages Stream
  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
    final String chatId = _getChatId(senderId, receiverId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get My Chats List Stream
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> chats = [];
          for (var doc in snapshot.docs) {
            Map<String, dynamic> chatData = doc.data();
            String otherUserId = chatData['otherUserId'];
            
            // Fetch other user details for display name/image
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists) {
              chatData['otherUserName'] = userDoc['name'] ?? 'Unknown User';
              chatData['otherUserImage'] = userDoc['imageUrl'] ?? '';
              chats.add(chatData);
            } else {
              // Fallback for Parents who don't have a 'users' record yet
              DocumentSnapshot studentDoc = await _firestore.collection('students').doc(otherUserId).get();
              if (studentDoc.exists) {
                chatData['otherUserName'] = studentDoc['fatherName'] != null 
                    ? "${studentDoc['fatherName']} (Parent)" 
                    : "Parent of ${studentDoc['name']}";
                chatData['otherUserImage'] = studentDoc['imageUrl'] ?? ''; 
                chats.add(chatData);
              }
            }
          }
          return chats;
        });
  }
  
  // Mark as Read
  Future<void> markAsRead(String userId, String otherUserId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('my_chats')
        .doc(otherUserId)
        .update({'unreadCount': 0});
  }

  // Get Total Unread Count Stream
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('my_chats')
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            total += (doc.data()['unreadCount'] ?? 0) as int;
          }
          return total;
        });
  }

  // Helper to find user ID by email
  Future<String?> getUserIdByEmail(String email) async {
    if (email.isEmpty) return null;
    
    // 1. Check primary 'users' collection
    final snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    
    // 2. Fallback: Check 'students' collection for parents (for older enrollments)
    final parentSnapshot = await _firestore.collection('students').where('parentEmail', isEqualTo: email).limit(1).get();
    if (parentSnapshot.docs.isNotEmpty) {
      return parentSnapshot.docs.first.id;
    }
    
    return null;
  }
}
