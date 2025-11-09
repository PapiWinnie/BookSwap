enum SwapStatus {
  pending,
  accepted,
  rejected,
  completed;

  String get displayName {
    switch (this) {
      case SwapStatus.pending:
        return 'Pending';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.rejected:
        return 'Rejected';
      case SwapStatus.completed:
        return 'Completed';
    }
  }

  static SwapStatus fromString(String value) {
    switch (value) {
      case 'Pending':
        return SwapStatus.pending;
      case 'Accepted':
        return SwapStatus.accepted;
      case 'Rejected':
        return SwapStatus.rejected;
      case 'Completed':
        return SwapStatus.completed;
      default:
        return SwapStatus.pending;
    }
  }
}

class SwapModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final SwapStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SwapModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // FIXED: Map senderId -> requesterId and receiverId -> ownerId for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'requesterId': senderId,      // ← Changed from 'senderId'
      'requesterName': senderName,  // ← Changed from 'senderName'
      'ownerId': receiverId,        // ← Changed from 'receiverId'
      'ownerName': receiverName,    // ← Changed from 'receiverName'
      'status': status.displayName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // FIXED: Map requesterId -> senderId and ownerId -> receiverId when reading
  factory SwapModel.fromMap(Map<String, dynamic> map) {
    return SwapModel(
      id: map['id'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      senderId: map['requesterId'] ?? map['senderId'] ?? '',      // ← Check both for backward compatibility
      senderName: map['requesterName'] ?? map['senderName'] ?? '', // ← Check both
      receiverId: map['ownerId'] ?? map['receiverId'] ?? '',       // ← Check both
      receiverName: map['ownerName'] ?? map['receiverName'] ?? '', // ← Check both
      status: SwapStatus.fromString(map['status'] ?? 'Pending'),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  SwapModel copyWith({
    SwapStatus? status,
    DateTime? updatedAt,
  }) {
    return SwapModel(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}