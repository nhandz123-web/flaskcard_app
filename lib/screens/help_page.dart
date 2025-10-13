import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Trang trợ giúp - Nội dung tượng trưng',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}