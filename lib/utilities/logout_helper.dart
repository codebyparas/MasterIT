import 'package:flutter/material.dart';
import 'package:learningdart/constants/routes.dart';
import 'package:learningdart/services/auth/auth_service.dart';

Future<void> handleLogout(BuildContext context) async {
  final shouldLogout = await showLogOutDialog(context);
  if (shouldLogout) {
    await AuthService.firebase().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(loginRoute, (_) => false);
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Sign Out'),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Log Out"),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}