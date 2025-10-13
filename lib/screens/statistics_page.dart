import 'package:flutter/material.dart';
import 'package:flashcard_app/services/api_service.dart';

class StatisticsPage extends StatelessWidget {
  final ApiService api;

  const StatisticsPage({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.me(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải thống kê'));
          } else if (snapshot.hasData) {
            final userData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thống kê học tập',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    label: 'Flashcard đã học',
                    value: userData['stats']['flashcards_learned'].toString(),
                  ),
                  _buildStatItem(
                    label: 'Từ vựng thành thạo',
                    value: userData['stats']['words_mastered'].toString(),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Không có dữ liệu'));
        },
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}