import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt), // Store as Timestamp
    };
  }

  // Create from Firestore Map - FIXED to handle both Timestamp and String
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle createdAt - can be either Timestamp or String
    DateTime createdAtDate;
    
    if (map['createdAt'] is Timestamp) {
      // From Firestore - it's a Timestamp
      createdAtDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      // From old data or other sources - it's a String
      createdAtDate = DateTime.parse(map['createdAt']);
    } else {
      // Fallback - use current time
      createdAtDate = DateTime.now();
    }

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      createdAt: createdAtDate,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}