import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

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
      if (mounted) {
        setState(() => me = data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.red, // Giữ màu đỏ theo yêu cầu
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/app/decks'), // Quay lại DeckPage
        ),
      ),
      body: Padding(
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/app/settings'), // Điều hướng đến Settings
              child: Text(AppLocalizations.of(context)!.settings),
            ),
          ],
        ),
      ),
    );
  }
}