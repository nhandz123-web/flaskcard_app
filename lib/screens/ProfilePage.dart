// import 'package:flutter/material.dart';
// import 'package:flashcard_app/services/api_service.dart';
//
// class ProfilePage extends StatelessWidget {
//   final ApiService api;
//
//   const ProfilePage({super.key, required this.api});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: FutureBuilder<Map<String, dynamic>>(
//           future: api.me(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             } else if (snapshot.hasError) {
//               return const Center(
//                   child: Text('Lỗi tải thông tin', style: TextStyle(color: Colors.white)));
//             } else if (snapshot.hasData) {
//               final userData = snapshot.data!;
//               return Column(
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(16),
//                         bottomRight: Radius.circular(16),
//                       ),
//                     ),
//                     child: const Text(
//                       '⚡ LexiFlash',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 22,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Container(
//                       color: Colors.grey[300],
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
//                             child: Text(
//                               'Hồ sơ',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             margin: const EdgeInsets.symmetric(horizontal: 16),
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withOpacity(0.2),
//                                   spreadRadius: 2,
//                                   blurRadius: 5,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 CircleAvatar(
//                                   radius: 30,
//                                   backgroundImage: userData['avatar'] != null
//                                       ? NetworkImage(userData['avatar'])
//                                       : null,
//                                   backgroundColor: Colors.black12,
//                                   child: userData['avatar'] == null
//                                       ? const Icon(Icons.person, size: 40)
//                                       : null,
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         userData['name'] ?? 'Không có tên',
//                                         style: const TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         userData['email'] ?? 'Không có email',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         'ID: ${userData['id'] ?? 'N/A'}',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           _buildInfoItem(
//                             icon: Icons.calendar_today,
//                             label: 'Ngày tạo tài khoản',
//                             value: userData['created_at'] ?? 'N/A',
//                           ),
//                           _buildInfoItem(
//                             icon: Icons.access_time,
//                             label: 'Lần đăng nhập gần nhất',
//                             value: userData['last_login'] ?? 'N/A',
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
//                             child: Text(
//                               'Thống kê',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           _buildInfoItem(
//                             icon: Icons.book,
//                             label: 'Flashcard đã học',
//                             value: userData['stats']['flashcards_learned'].toString(),
//                           ),
//                           _buildInfoItem(
//                             icon: Icons.star,
//                             label: 'Từ vựng thành thạo',
//                             value: userData['stats']['words_mastered'].toString(),
//                           ),
//                           const Spacer(),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }
//             return const Center(
//                 child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white)));
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoItem({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       child: Row(
//         children: [
//           Icon(icon, size: 24, color: Colors.black87),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }