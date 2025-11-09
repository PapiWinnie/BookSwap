// fixed warning: use debugPrint instead of print for production-safe logging
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/book_model.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider((ref) => StorageService());

// FIXED: All books - now requires authentication to prevent permission errors
final booksProvider = StreamProvider<List<BookModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      // Only query Firestore when user is authenticated
      if (user == null) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('books')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BookModel.fromMap(doc.data()))
                .toList(),
          )
          .handleError((error) {
            // fixed warning: replaced print with debugPrint
            debugPrint('Error loading books: $error');
          });
    },
    // CRITICAL FIX: Wait for auth resolution before querying
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value([]),
  );
});

// User's books - FIXED: Added proper auth handling
final myBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('books')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            // Sort in memory instead of using composite index
            final books = snapshot.docs
                .map((doc) => BookModel.fromMap(doc.data()))
                .toList();

            // Sort by createdAt descending (newest first)
            books.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return books;
          })
          .handleError((error) {
            // fixed warning: replaced print with debugPrint
            debugPrint('Error loading my books: $error');
          });
    },
    // CRITICAL FIX: Wait for auth resolution before querying
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value([]),
  );
});

class BooksNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  BooksNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> addBook({
    required String title,
    required String author,
    required BookCondition condition,
    File? imageFile,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(firebaseServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userData = await ref
          .read(firebaseServiceProvider)
          .getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ref
            .read(storageServiceProvider)
            .uploadBookCover(imageFile, user.uid);
      }

      final bookId = FirebaseFirestore.instance.collection('books').doc().id;

      final book = BookModel(
        id: bookId,
        title: title,
        author: author,
        condition: condition,
        imageUrl: imageUrl,
        ownerId: user.uid,
        ownerName: userData.name,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .set(book.toMap());

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required BookCondition condition,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(firebaseServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? imageUrl = existingImageUrl;

      if (imageFile != null) {
        // Delete old image if exists
        if (existingImageUrl != null) {
          await ref.read(storageServiceProvider).deleteImage(existingImageUrl);
        }

        imageUrl = await ref
            .read(storageServiceProvider)
            .uploadBookCover(imageFile, user.uid);
      }

      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'title': title,
        'author': author,
        'condition': condition.displayName,
        'imageUrl': imageUrl,
      });

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteBook(String bookId, String? imageUrl) async {
    state = const AsyncValue.loading();

    try {
      // Delete image if exists
      if (imageUrl != null) {
        await ref.read(storageServiceProvider).deleteImage(imageUrl);
      }

      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final booksNotifierProvider =
    StateNotifierProvider<BooksNotifier, AsyncValue<void>>((ref) {
      return BooksNotifier(ref);
    });
