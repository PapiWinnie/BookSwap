import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  // fixed warning: use super.key for constructors
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = true;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.white38),
                  const SizedBox(height: 16),
                  const Text(
                    'No user logged in',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(firebaseServiceProvider).signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C842),
                      foregroundColor: const Color(0xFF1A1D2E),
                    ),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF2D3142),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFF5C842),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1D2E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // fixed warning: .withOpacity deprecated — use withAlpha to preserve behavior
                          color: user.emailVerified
                              ? Colors.green.withAlpha((0.2 * 255).round())
                              : Colors.orange.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.emailVerified
                                  ? Icons.verified
                                  : Icons.warning,
                              size: 16,
                              color: user.emailVerified
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.emailVerified ? 'Verified' : 'Not Verified',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: user.emailVerified
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notifications Section
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF2D3142),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Notification reminders',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Get notified about swap requests',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: _notificationsEnabled,
                      // fixed warning: activeColor deprecated — use activeThumbColor
                      activeThumbColor: const Color(0xFFF5C842),
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    const Divider(color: Color(0xFF1A1D2E), height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Email Updates',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Receive updates via email',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: _emailUpdatesEnabled,
                      // fixed warning: activeColor deprecated — use activeThumbColor
                      activeThumbColor: const Color(0xFFF5C842),
                      onChanged: (value) {
                        setState(() => _emailUpdatesEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF2D3142),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'App Version',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Text(
                        '1.0.0',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const Divider(color: Color(0xFF1A1D2E), height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'Terms of Service',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onTap: () {
                        // Handle terms tap
                      },
                    ),
                    const Divider(color: Color(0xFF1A1D2E), height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'Privacy Policy',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onTap: () {
                        // Handle privacy tap
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF2D3142),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(color: Colors.white70),
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
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await ref.read(firebaseServiceProvider).signOut();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF5C842)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
