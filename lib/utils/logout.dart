import 'package:flutter/material.dart';

import '../services/user_service.dart';

/// Asks first, then signs the user out (Firebase or DummyJSON) and returns to
/// the sign in screen. Used by both Settings and Profile.
Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await userService.value.logout();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
}
