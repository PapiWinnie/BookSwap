import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/books_provider.dart';
import '../../widgets/book_card.dart';
import '../books/add_book_screen.dart';
import '../books/edit_book_screen.dart';

class MyListingsScreen extends ConsumerWidget {
  // fixed warning: use super.key for constructors
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myBooksAsync = ref.watch(myBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: myBooksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.library_add_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No listings yet',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first book',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddBookScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C842),
                      foregroundColor: const Color(0xFF1A1D2E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: books.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                showActions: true,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBookScreen(book: book),
                    ),
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2D3142),
                      title: const Text(
                        'Delete Book',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Are you sure you want to delete "${book.title}"?',
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
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref
                        .read(booksNotifierProvider.notifier)
                        .deleteBook(book.id, book.imageUrl);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Book deleted successfully!'),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBookScreen()),
          );
        },
        backgroundColor: const Color(0xFFF5C842),
        foregroundColor: const Color(0xFF1A1D2E),
        child: const Icon(Icons.add),
      ),
    );
  }
}
