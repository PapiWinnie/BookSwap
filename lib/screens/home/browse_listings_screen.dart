import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/books_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swaps_provider.dart';
import '../../widgets/book_card.dart';

class BrowseListingsScreen extends ConsumerWidget {
  // fixed warning: use super.key for constructors
  const BrowseListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        title: const Text('Browse Listings'),
        backgroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No books available yet',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to list a book!',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return currentUserAsync.when(
            data: (currentUser) {
              final otherBooks = books
                  .where((book) => book.ownerId != currentUser?.id)
                  .toList();

              if (otherBooks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 64,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No books from other users',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: otherBooks.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final book = otherBooks[index];
                  return BookCard(
                    book: book,
                    onSwap: () async {
                      if (currentUser == null) return;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2D3142),
                          title: const Text(
                            'Request Swap',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'Send a swap request for "${book.title}"?',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5C842),
                                foregroundColor: const Color(0xFF1A1D2E),
                              ),
                              child: const Text('Send Request'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref
                            .read(swapsNotifierProvider.notifier)
                            .createSwap(
                              book: book,
                              senderName: currentUser.name,
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Swap request sent!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5C842)),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF5C842)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
