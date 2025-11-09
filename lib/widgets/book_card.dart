import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/book_model.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;
  final VoidCallback? onSwap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  // fixed warning: use super.key for constructors
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onSwap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  Color _getConditionColor() {
    switch (book.condition) {
      case BookCondition.newCondition:
        return Colors.green;
      case BookCondition.likeNew:
        return Colors.blue;
      case BookCondition.good:
        return Colors.orange;
      case BookCondition.used:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D3142),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.imageUrl!,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 120,
                          color: const Color(0xFF1A1D2E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF5C842),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 120,
                          color: const Color(0xFF1A1D2E),
                          child: const Icon(
                            Icons.book,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 120,
                        color: const Color(0xFF1A1D2E),
                        child: const Icon(
                          Icons.book,
                          color: Colors.white70,
                          size: 40,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // fixed warning: .withOpacity deprecated — use withAlpha to preserve behavior
                        color: _getConditionColor().withAlpha(
                          (0.2 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.condition.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getConditionColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.ownerName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(book.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),

                    if (showActions) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (onEdit != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF5C842),
                                  side: const BorderSide(
                                    color: Color(0xFFF5C842),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          if (onEdit != null && onDelete != null)
                            const SizedBox(width: 8),
                          if (onDelete != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onDelete,
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    if (onSwap != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: book.isAvailable ? onSwap : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5C842),
                            foregroundColor: const Color(0xFF1A1D2E),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            book.isAvailable ? 'Swap' : 'Unavailable',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
