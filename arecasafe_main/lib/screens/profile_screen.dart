// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthServices.currentUser();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 8),
        Text("ArecaSafe", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text("User: ${user?.email ?? 'guest'}"),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () async {
          await AuthServices.signOut();
          // restart app to show login
          Navigator.of(context).pushReplacementNamed('/');
        }, child: const Text("Sign out"))
      ]),
    );
  }
}
