import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/chats_provider.dart';
import '../chat/chat_detail_screen.dart';

class ChatsScreen extends ConsumerWidget {
  // fixed warning: use super.key for constructors
  const ChatsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start by requesting a book swap',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final lastMessageTime = chat['lastMessageTime'] as DateTime?;

              return Card(
                color: const Color(0xFF2D3142),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF5C842),
                    child: Text(
                      chat['otherUserName'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    chat['otherUserName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['bookTitle'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              // fixed warning: .withOpacity deprecated — use withAlpha to preserve behavior
                              color: _getStatusColor(
                                chat['status'],
                              ).withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              chat['status'],
                              style: TextStyle(
                                fontSize: 11,
                                color: _getStatusColor(chat['status']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chat['lastMessage'],
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: lastMessageTime != null
                      ? Text(
                          DateFormat('MMM dd').format(lastMessageTime),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          swapId: chat['swapId'],
                          otherUserName: chat['otherUserName'],
                          bookTitle: chat['bookTitle'],
                        ),
                      ),
                    );
                  },
                ),
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
    );
  }
}
