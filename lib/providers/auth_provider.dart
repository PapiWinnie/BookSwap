// fixed warning: use debugPrint instead of print for production-safe logging
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

// FIXED: Proper stream transformation for currentUserProvider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        // fixed warning: replaced print with debugPrint
        debugPrint('🔴 currentUserProvider - NO USER');
        return Stream.value(null);
      }

      // fixed warning: replaced print with debugPrint
      debugPrint('🔵 currentUserProvider - Auth User: ${user.uid}');

      // Convert Future to Stream and handle errors
      return Stream.fromFuture(
            ref.read(firebaseServiceProvider).getUserData(user.uid),
          )
          .handleError((error) {
            // fixed warning: replaced print with debugPrint
            debugPrint(
              '❌ currentUserProvider - Error fetching user data: $error',
            );
            return null;
          })
          .map((userData) {
            // fixed warning: replaced print with debugPrint
            debugPrint('🟢 currentUserProvider - User Data: ${userData?.name}');
            return userData;
          });
    },
    loading: () {
      // fixed warning: replaced print with debugPrint
      debugPrint('⏳ currentUserProvider - Auth Loading');
      return const Stream.empty();
    },
    error: (error, stack) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ currentUserProvider - Auth Error: $error');
      return Stream.value(null);
    },
  );
});
