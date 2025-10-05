// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/api_service.dart';
// import 'package:flashcard_app/models/card.dart' as card_model; // Thêm alias
//
// class CardFormPage extends StatefulWidget {
//   final ApiService api;
//   final int deckId;
//   final card_model.Card? card; // Sử dụng alias
//
//   const CardFormPage({super.key, required this.api, required this.deckId, this.card});
//
//   @override
//   State<CardFormPage> createState() => _CardFormPageState();
// }
//
// class _CardFormPageState extends State<CardFormPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _frontController = TextEditingController();
//   final _backController = TextEditingController();
//   final _noteController = TextEditingController();
//   File? _imageFile;
//   String? _imageUrl;
//   bool _uploading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.card != null) {
//       _frontController.text = widget.card!.front;
//       _backController.text = widget.card!.back;
//       _noteController.text = widget.card!.note ?? '';
//       _imageUrl = widget.card!.imageUrl;
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() => _imageFile = File(picked.path));
//     }
//   }
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _uploading = true);
//     try {
//       final cardData = {
//         'front': _frontController.text.trim(),
//         'back': _backController.text.trim(),
//         'note': _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
//       };
//       card_model.Card newCard; // Sử dụng alias
//       if (widget.card == null) {
//         newCard = await widget.api.createCard(widget.deckId, cardData['front']!, cardData['back']!, cardData['note']);
//       } else {
//         newCard = await widget.api.updateCard(widget.card!.id, cardData); // Đã thêm updateCard
//       }
//       if (_imageFile != null) {
//         _imageUrl = await widget.api.uploadCardImage(newCard.id, _imageFile!);
//       }
//       if (mounted) Navigator.pop(context);
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
//     } finally {
//       if (mounted) setState(() => _uploading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.card == null ? 'Thêm Card' : 'Sửa Card')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: _frontController,
//                 decoration: InputDecoration(labelText: 'Mặt trước'),
//                 validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
//               ),
//               TextFormField(
//                 controller: _backController,
//                 decoration: InputDecoration(labelText: 'Mặt sau'),
//                 validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
//               ),
//               TextFormField(
//                 controller: _noteController,
//                 decoration: InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
//               ),
//               SizedBox(height: 16),
//               if (_imageUrl != null || _imageFile != null)
//                 SizedBox(
//                   height: 200,
//                   child: _imageFile != null
//                       ? Image.file(_imageFile!)
//                       : Image.network(_imageUrl!),
//                 ),
//               ElevatedButton(onPressed: _pickImage, child: Text('Chọn ảnh')),
//               if (_uploading) CircularProgressIndicator(),
//               SizedBox(height: 16),
//               ElevatedButton(onPressed: _submit, child: Text('Lưu')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _frontController.dispose();
//     _backController.dispose();
//     _noteController.dispose();
//     super.dispose();
//   }
// }