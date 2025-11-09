// fixed warning: use debugPrint instead of print for production-safe logging
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap_model.dart';
import '../models/book_model.dart';
import 'auth_provider.dart';

// FIXED: Properly handle authentication state before querying
final swapsProvider = StreamProvider<List<SwapModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      // CRITICAL FIX: Return empty stream if no user
      if (user == null) {
        return Stream.value([]);
      }

      // Only query Firestore when user is authenticated
      return FirebaseFirestore.instance
          .collection('swaps')
          .where('requesterId', isEqualTo: user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => SwapModel.fromMap(doc.data()))
                .toList(),
          )
          .handleError((error) {
            // fixed warning: replaced print with debugPrint
            debugPrint('Error loading swaps: $error');
          });
    },
    // CRITICAL FIX: Don't return empty list in loading state - wait for auth
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value([]),
  );
});

final receivedSwapsProvider = StreamProvider<List<SwapModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      // CRITICAL FIX: Return empty stream if no user
      if (user == null) {
        return Stream.value([]);
      }

      // Only query Firestore when user is authenticated
      return FirebaseFirestore.instance
          .collection('swaps')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => SwapModel.fromMap(doc.data()))
                .toList(),
          )
          .handleError((error) {
            // fixed warning: replaced print with debugPrint
            debugPrint('Error loading received swaps: $error');
          });
    },
    // CRITICAL FIX: Don't return empty list in loading state - wait for auth
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value([]),
  );
});

class SwapsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SwapsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> createSwap({
    required BookModel book,
    required String senderName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(firebaseServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      final swapId = FirebaseFirestore.instance.collection('swaps').doc().id;

      final swap = SwapModel(
        id: swapId,
        bookId: book.id,
        bookTitle: book.title,
        senderId: user.uid,
        senderName: senderName,
        receiverId: book.ownerId,
        receiverName: book.ownerName,
        status: SwapStatus.pending,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('swaps')
          .doc(swapId)
          .set(swap.toMap());

      // Update book availability
      await FirebaseFirestore.instance.collection('books').doc(book.id).update({
        'isAvailable': false,
      });

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateSwapStatus({
    required String swapId,
    required SwapStatus status,
    required String bookId,
  }) async {
    state = const AsyncValue.loading();

    try {
      await FirebaseFirestore.instance.collection('swaps').doc(swapId).update({
        'status': status.displayName,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // If rejected, make book available again
      if (status == SwapStatus.rejected) {
        await FirebaseFirestore.instance.collection('books').doc(bookId).update(
          {'isAvailable': true},
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final swapsNotifierProvider =
    StateNotifierProvider<SwapsNotifier, AsyncValue<void>>((ref) {
      return SwapsNotifier(ref);
    });
