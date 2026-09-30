import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// All registered users, including the signed-in one (the UI filters it out).
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('Users').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  /// Same room ID for any two users, regardless of who opens the chat.
  String chatRoomId(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    return ids.join('_');
  }

  /// The sender is passed in (rather than read from FirebaseAuth) so DummyJSON
  /// users, who have no Firebase account, can chat too.
  Future<void> sendMessage({
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String message,
  }) async {
    final newMessage = MessageModel(
      senderId: senderId,
      senderEmail: senderEmail,
      receiverId: receiverId,
      message: message,
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(senderId, receiverId))
        .collection('messages')
        .add(newMessage.toMap());
  }

  /// Newest first; the chat screen shows the list reversed.
  /// Includes metadata changes so the UI can tell pending (unsent) writes apart.
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessage(
    String userId,
    String otherUserId,
  ) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(userId, otherUserId))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  /// Flags messages received from [otherUserId] as seen.
  Future<void> markAsRead(String userId, String otherUserId) async {
    final messages = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(userId, otherUserId))
        .collection('messages');
    final unread = await messages
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
