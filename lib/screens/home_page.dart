import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class HomePage extends StatelessWidget {
  final ApiService api;

  const HomePage({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userId != null ? 'User' : 'User'; // Thay bằng tên từ API sau

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Nền đen
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              color: const Color(0xFFBF360C).withOpacity(0.8), // Red600 nhạt hơn
              child: const Text(
                "⚡ LexiFlash",
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Avatar + Welcome text
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  // backgroundImage: AssetImage("assets/pepe.png"), // Thêm vào pubspec.yaml
                  backgroundColor: const Color(0xFF4B4B4B), // Grey700
                ),
                SizedBox(height: 10),
              ],
            ),
            Text.rich(
              TextSpan(
                text: "Chào mừng ",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFB0BEC5), // White70
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: userName,
                    style: const TextStyle(
                      color: Color(0xFFEF5350), // Red400
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: " đã quay trở lại !"),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            // Card mục tiêu (không nổi)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF212121), // Grey850
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF424242), width: 1), // Grey800
              ),
              child: Column(
                children: [
                  Text(
                    "Thẻ đến hạn hôm nay\n15 thẻ - mục tiêu: 20 thẻ/ngày",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: const Color(0xFFB0BEC5)),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350), // Red400
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _navigateToDecks(context),
                child: Text(
                  "Học Ngay",
                  style: TextStyle(fontSize: 15, color: const Color(0xFFFFFFFF)),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Streak box (không nổi)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF212121), // Grey850
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF424242), width: 1), // Grey800
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Streak: 7 ngày",
                    style: TextStyle(fontSize: 15, color: const Color(0xFFB0BEC5)),
                  ),
                  Icon(Icons.check_box, color: const Color(0xFFEF5350), size: 20),
                ],
              ),
            ),

            Expanded(child: SizedBox.shrink()),

            // Bottom Navigation bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Grey900
                border: Border(
                  top: BorderSide(color: const Color(0xFF616161), width: 1), // Grey700
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(icon: Icons.home, label: "Home", active: true),
                  _BottomNavItem(
                    icon: Icons.library_books, // Thay bằng biểu tượng Decks
                    label: "Decks",
                    onTap: () => _navigateToDecks(context),
                  ),
                  _BottomNavItem(icon: Icons.people, label: ""),
                  _BottomNavItem(icon: Icons.settings, label: ""),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDecks(BuildContext context) {
    context.go('/app/decks');
  }
}

// Widget riêng cho bottom nav
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
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}