import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/swaps_provider.dart';
import '../../models/swap_model.dart';

class SwapRequestsScreen extends ConsumerWidget {
  // fixed warning: use super.key for constructors
  const SwapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedSwaps = ref.watch(receivedSwapsProvider);
    final sentSwaps = ref.watch(swapsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1D2E),
        appBar: AppBar(
          title: const Text('Swap Requests'),
          backgroundColor: const Color(0xFF2D3142),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF5C842),
            labelColor: Color(0xFFF5C842),
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Received Requests Tab
            receivedSwaps.when(
              data: (swaps) {
                if (swaps.isEmpty) {
                  return _buildEmptyState('No swap requests received');
                }
                return _buildSwapList(context, ref, swaps, isReceived: true);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF5C842)),
              ),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),

            // Sent Requests Tab
            sentSwaps.when(
              data: (swaps) {
                if (swaps.isEmpty) {
                  return _buildEmptyState('No swap requests sent');
                }
                return _buildSwapList(context, ref, swaps, isReceived: false);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF5C842)),
              ),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapList(
    BuildContext context,
    WidgetRef ref,
    List<SwapModel> swaps, {
    required bool isReceived,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: swaps.length,
      itemBuilder: (context, index) {
        final swap = swaps[index];
        return _buildSwapCard(context, ref, swap, isReceived);
      },
    );
  }

  Widget _buildSwapCard(
    BuildContext context,
    WidgetRef ref,
    SwapModel swap,
    bool isReceived,
  ) {
    final statusColor = _getStatusColor(swap.status);
    final canTakeAction = isReceived && swap.status == SwapStatus.pending;

    return Card(
      color: const Color(0xFF2D3142),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Title
            Text(
              swap.bookTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // User Info
            Row(
              children: [
                Icon(
                  isReceived ? Icons.person : Icons.send,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  isReceived
                      ? 'From: ${swap.senderName}'
                      : 'To: ${swap.receiverName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // fixed warning: .withOpacity deprecated — use withAlpha to preserve behavior
                    color: statusColor.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    swap.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(swap.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),

            // Action Buttons (only for received pending requests)
            if (canTakeAction) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(context, ref, swap),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleReject(context, ref, swap),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAccept(
    BuildContext context,
    WidgetRef ref,
    SwapModel swap,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3142),
        title: const Text(
          'Accept Swap Request',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Accept swap request from ${swap.senderName} for "${swap.bookTitle}"?',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref
          .read(swapsNotifierProvider.notifier)
          .updateSwapStatus(
            swapId: swap.id,
            status: SwapStatus.accepted,
            bookId: swap.bookId,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swap request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleReject(
    BuildContext context,
    WidgetRef ref,
    SwapModel swap,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3142),
        title: const Text(
          'Reject Swap Request',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Reject swap request from ${swap.senderName} for "${swap.bookTitle}"?',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref
          .read(swapsNotifierProvider.notifier)
          .updateSwapStatus(
            swapId: swap.id,
            status: SwapStatus.rejected,
            bookId: swap.bookId,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Swap request rejected. Book is now available again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return Colors.orange;
      case SwapStatus.accepted:
        return Colors.green;
      case SwapStatus.rejected:
        return Colors.red;
      case SwapStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading swaps',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
