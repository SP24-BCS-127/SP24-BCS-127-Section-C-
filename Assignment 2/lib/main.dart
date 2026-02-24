import 'package:flutter/material.dart';

void main() => runApp(const ProfileCardApp());

class ProfileCardApp extends StatelessWidget {
  const ProfileCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const ProfileCardPage(),
    );
  }
}

class ProfileCardPage extends StatelessWidget {
  const ProfileCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: scheme.onPrimary,
                backgroundImage: const AssetImage('images/123.jpg'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Haseeb Ahmad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Flutter Developer',
                style: TextStyle(
                  color: Colors.teal.shade100,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                child: Divider(color: Colors.teal.shade100, thickness: 1),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.phone, color: scheme.primary),
                  title: const Text('+92555 010 999'),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.email, color: scheme.primary),
                  title: const Text('haseebahmad03156078199@gmail.com'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link),
                label: const Text('COMSATS University Vehari Campus'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
