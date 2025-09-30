import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/deck.dart';

class DeckPage extends StatelessWidget {
  final ApiService api;

  const DeckPage({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Nền đen đồng bộ
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              color: const Color(0xFFBF360C), // Red600
              child: const Text(
                "⚡ LexiFlash",
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Grid danh sách bộ thẻ
            Expanded(
              child: FutureBuilder<List<Deck>>(
                future: api.getDecks(), // Gọi API với kiểu Future<List<Deck>>
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFEF5350)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Color(0xFFB0BEC5)),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có deck nào',
                        style: TextStyle(color: Color(0xFFB0BEC5)),
                      ),
                    );
                  }

                  final decks = snapshot.data!;
                  return Container(
                    color: const Color(0xFFE0E0E0), // Grey300
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      itemCount: decks.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemBuilder: (context, index) {
                        final deck = decks[index];
                        return GestureDetector(
                          onTap: () {
                            context.go('/app/deck/${deck.id}/cards');
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deck.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF000000),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          deck.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF757575),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Ngày tạo: ${deck.createdAt.toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FloatingActionButton
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF5350), // Red400
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onPressed: () {
          context.go('/app/create-deck'); // Điều hướng đến trang tạo deck
        },
        child: const Icon(Icons.add, size: 32, color: Color(0xFFFFFFFF)),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          border: Border(top: BorderSide(color: Color(0xFF616161), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home,
              label: "Home",
              onTap: () => context.go('/home'),
            ),
            _BottomNavItem(
              icon: Icons.library_books,
              label: "Deck",
              active: true,
              onTap: () => context.go('/app/decks'),
            ),
            _BottomNavItem(
              icon: Icons.people,
              label: "",
              onTap: () {},
            ),
            _BottomNavItem(
              icon: Icons.account_circle,
              label: "",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// Widget riêng cho bottom nav item
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    this.label = "",
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEF5350) : const Color(0xFFB0BEC5), size: 22),
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFFEF5350) : const Color(0xFFB0BEC5),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}