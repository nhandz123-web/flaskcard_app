import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';

import '../../core/settings/settings_provider.dart';
import '../../core/notifications/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsProvider _settings;

  @override
  void initState() {
    super.initState();
    _settings = Provider.of<SettingsProvider>(context, listen: false);
    print('SettingsPage initialized with fontScale=${_settings.fontScale}, locale=${_settings.locale}');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final spFuture = SharedPreferences.getInstance();
    print('Building SettingsPage with locale=${t.localeName}');

    return Scaffold(
      appBar: AppBar(title: Text(t.settings_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionCard(
            title: t.settings_title,
            children: [
              // Font size
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(t.font_size), // t.font_size từ AppLocalizations
                subtitle: Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return Text('${(settings.animatedFontScale * 100).round()}%');
                  },
                ),
                contentPadding: EdgeInsets.zero,
                trailing: SizedBox(
                  width: 180,
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1), // Thời gian animation
                        tween: Tween<double>(begin: settings.fontScale, end: settings.animatedFontScale),
                        builder: (context, value, child) {
                          return Slider(
                            value: value,
                            min: 0.85,
                            max: 1.40,
                            divisions: 11,
                            onChanged: (newValue) {
                              settings.setFontScale(newValue); // Cập nhật giá trị
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 12),
              // Theme mode
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(t.theme),
                contentPadding: EdgeInsets.zero,
                subtitle: DropdownButton<ThemeMode>(
                  value: _settings.themeMode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (m) => m != null ? _settings.setThemeMode(m) : null,
                ),
              ),
              const Divider(height: 12),
              // Language
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(t.language),
                contentPadding: EdgeInsets.zero,
                subtitle: DropdownButton<String>(
                  value: _settings.locale.languageCode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (code) => code != null ? _settings.setLocale(Locale(code)) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Study section
          _SectionCard(
            title: 'Study',
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return ListTile(
                    leading: const Icon(Icons.volume_up),
                    title: Text(t.auto_play),
                    contentPadding: EdgeInsets.zero,
                    trailing: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Switch(
                        key: ValueKey(settings.animatedAutoPlay),
                        value: settings.animatedAutoPlay,
                        onChanged: (v) => settings.setAutoPlay(v),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Notifications section
          _SectionCard(
            title: t.daily_reminder,
            children: [
              ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(t.daily_reminder),
                subtitle: FutureBuilder<SharedPreferences>(
                  future: spFuture,
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const Text('…');
                    final val = snap.data!.getString('dailyReminder');
                    return Text(val == null ? t.turn_off : '• $val');
                  },
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => _pickDailyReminder(),
                  child: Text(t.pick_time),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.close),
                  onPressed: () => _turnOffDailyReminder(),
                  label: Text(t.turn_off),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hint
          Text(
            t.settings_hint,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Hàm pick reminder
  Future<void> _pickDailyReminder() async {
    final t = AppLocalizations.of(context)!;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      await NotificationService.I.scheduleDaily(picked.hour, picked.minute);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('dailyReminder', '${picked.hour}:${picked.minute}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.daily_reminder}: ${picked.format(context)}')),
        );
      }
    }
  }

  // Hàm turn off reminder
  Future<void> _turnOffDailyReminder() async {
    final t = AppLocalizations.of(context)!;
    await NotificationService.I.cancelDaily();
    final sp = await SharedPreferences.getInstance();
    await sp.remove('dailyReminder');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.daily_reminder} • ${t.turn_off}')),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}