// fixed warning: use debugPrint instead of print for production-safe logging
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'auth_provider.dart';

// FIXED: Add authentication check for chat messages
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  swapId,
) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('chats')
          .doc(swapId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => MessageModel.fromMap(doc.data()))
                .toList(),
          )
          .handleError((error) {
            // fixed warning: replaced print with debugPrint
            debugPrint('Error loading messages: $error');
          });
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value([]),
  );
});

// FIXED: Changed field names to match Firestore rules (requesterId/ownerId)
final chatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async* {
      if (user == null) {
        yield [];
        return;
      }

      try {
        // Get all swaps where user is requester
        final swapsSnapshot = await FirebaseFirestore.instance
            .collection('swaps')
            .where('requesterId', isEqualTo: user.uid) // Changed from senderId
            .get();

        // Get all swaps where user is owner
        final receivedSwapsSnapshot = await FirebaseFirestore.instance
            .collection('swaps')
            .where('ownerId', isEqualTo: user.uid) // Changed from receiverId
            .get();

        final allSwaps = [...swapsSnapshot.docs, ...receivedSwapsSnapshot.docs];

        final List<Map<String, dynamic>> chats = [];

        for (final swapDoc in allSwaps) {
          final swapData = swapDoc.data();

          // Get last message
          final messagesSnapshot = await FirebaseFirestore.instance
              .collection('chats')
              .doc(swapDoc.id)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          String lastMessage = 'No messages yet';
          DateTime? lastMessageTime;

          if (messagesSnapshot.docs.isNotEmpty) {
            final message = MessageModel.fromMap(
              messagesSnapshot.docs.first.data(),
            );
            lastMessage = message.text;
            lastMessageTime = message.timestamp;
          }

          // FIXED: Use requesterId/ownerId instead of senderId/receiverId
          chats.add({
            'swapId': swapDoc.id,
            'bookTitle': swapData['bookTitle'] ?? 'Unknown Book',
            'otherUserName': swapData['requesterId'] == user.uid
                ? (swapData['ownerName'] ?? 'Unknown User')
                : (swapData['requesterName'] ?? 'Unknown User'),
            'lastMessage': lastMessage,
            'lastMessageTime': lastMessageTime,
            'status': swapData['status'] ?? 'Unknown',
          });
        }

        // Sort by last message time
        chats.sort((a, b) {
          final aTime = a['lastMessageTime'] as DateTime?;
          final bTime = b['lastMessageTime'] as DateTime?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        yield chats;
      } catch (e) {
        // fixed warning: replaced print with debugPrint
        debugPrint('Error loading chats: $e');
        yield [];
      }
    },
    // CRITICAL FIX: Wait for auth resolution
    loading: () => const Stream.empty(),
    error: (error, stack) {
      // fixed warning: replaced print with debugPrint
      debugPrint('Chats provider error: $error');
      return Stream.value([]);
    },
  );
});

class ChatsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ChatsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required String swapId,
    required String text,
    required String senderName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(firebaseServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create chat document if it doesn't exist
      final chatDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(swapId);
      final chatSnapshot = await chatDoc.get();

      if (!chatSnapshot.exists) {
        // Get swap data to create chat with participants
        final swapDoc = await FirebaseFirestore.instance
            .collection('swaps')
            .doc(swapId)
            .get();

        if (swapDoc.exists) {
          final swapData = swapDoc.data()!;
          await chatDoc.set({
            'participants': [swapData['requesterId'], swapData['ownerId']],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final messageId = FirebaseFirestore.instance
          .collection('chats')
          .doc(swapId)
          .collection('messages')
          .doc()
          .id;

      final message = MessageModel(
        id: messageId,
        swapId: swapId,
        senderId: user.uid,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(swapId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      // fixed warning: replaced print with debugPrint
      debugPrint('Error sending message: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final chatsNotifierProvider =
    StateNotifierProvider<ChatsNotifier, AsyncValue<void>>((ref) {
      return ChatsNotifier(ref);
    });
