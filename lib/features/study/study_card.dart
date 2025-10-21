// // lib/features/study/study_card.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_session/audio_session.dart';
// import 'package:flashcard_app/l10n/app_localizations.dart';
//
// import '../../core/settings/settings_provider.dart';
//
// // Ví dụ model của 1 thẻ
// class StudyCardModel {
//   final String id;
//   final String front;
//   final String back;
//   final String? audioUrl;
//   StudyCardModel({required this.id, required this.front, required this.back, this.audioUrl});
// }
//
// class StudyCard extends StatefulWidget {
//   const StudyCard({super.key, required this.card});
//   final StudyCardModel card;
//
//   @override
//   State<StudyCard> createState() => _StudyCardState();
// }
//
// class _StudyCardState extends State<StudyCard> {
//   final _player = AudioPlayer();
//   String? _playedForCardId;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAudioSession();
//   }
//
//   Future<void> _initAudioSession() async {
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.speech());
//   }
//
//   Future<void> _maybeAutoplay() async {
//     final settings = context.read<SettingsProvider>();
//     final url = widget.card.audioUrl;
//     if (!settings.autoPlayAudio || url == null) return;
//     if (_playedForCardId == widget.card.id) return; // tránh phát lại khi rebuild
//
//     try {
//       await _player.setUrl(url);
//       await _player.play();
//       _playedForCardId = widget.card.id;
//     } catch (_) {
//       // optional: show snack/log
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _maybeAutoplay();
//   }
//
//   @override
//   void didUpdateWidget(covariant StudyCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.card.id != widget.card.id) {
//       _playedForCardId = null;
//       _maybeAutoplay();
//     }
//   }
//
//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!;
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(widget.card.front, style: Theme.of(context).textTheme.headlineSmall),
//             const SizedBox(height: 12),
//             Text(widget.card.back),
//             const SizedBox(height: 16),
//             if (widget.card.audioUrl != null)
//               IconButton(
//                 tooltip: t.study_play,
//                 onPressed: () async {
//                   await _player.setUrl(widget.card.audioUrl!);
//                   _player.play();
//                 },
//                 icon: const Icon(Icons.volume_up),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
