import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget{
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: user == null
        ? const Center(child: Text('User information could not load'))
        : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Username:', style: Theme.of(context).textTheme.titleMedium),
              Text(user.username, style: Theme.of(context).textTheme.titleLarge),
              const Divider(),

              Text('Email:', style: Theme.of(context).textTheme.titleMedium),
              Text(user.email),
              const Divider(),

              Text('Role:', style: Theme.of(context).textTheme.titleMedium),
              Text(user.role.toUpperCase()),
              const Divider(),

              Text('Kindness Points:', style: Theme.of(context).textTheme.titleMedium),
              Text('${user.kindnessPoints}', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.green)),
              const Divider(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)
                ),),
            ],
          ),),
    );
  }
}