import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.api});
  final ApiService api;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? me;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.me();
      if (mounted) { // Kiểm tra mounted trước khi setState
        setState(() => me = data);
      }
    } catch (e) {
      if (mounted) { // Kiểm tra mounted trước khi setState
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: error != null
          ? Text('Lỗi: $error')
          : me == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${me!['id']}'),
          Text('Name: ${me!['name']}'),
          Text('Email: ${me!['email']}'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await widget.api.logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}