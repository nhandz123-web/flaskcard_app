import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/notifications/notification_service.dart';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late final SettingsProvider _settings;
  late final AnimationController _animationController;
  late SharedPreferences _prefs;
  Timer? _debounceTimer;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _settings = Provider.of<SettingsProvider>(context, listen: false);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    // Preload SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _prefs = prefs;
          _isLoadingPrefs = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _isLoadingPrefs
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.settings_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 4, // 3 sections + hint
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildAnimatedSection(
                        delay: 0,
                        child: _buildAppearanceSection(t),
                      );
                    case 1:
                      return _buildAnimatedSection(
                        delay: 50,
                        child: _buildStudySection(t),
                      );
                    case 2:
                      return _buildAnimatedSection(
                        delay: 100,
                        child: _buildNotificationSection(t),
                      );
                    case 3:
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: Consumer<SettingsProvider>(
                          builder: (context, settings, _) => Center(
                            child: Text(
                              t.settings_hint,
                              style: TextStyle(
                                fontSize: 12 * settings.fontScale,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 8 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: child,
    );
  }

  Widget _buildAppearanceSection(AppLocalizations t) {
    return _SectionCard(
      icon: Icons.palette_rounded,
      title: 'Giao diện',
      iconColor: Colors.purple.shade400,
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => ListTile(
            leading: Icon(Icons.text_fields_rounded, color: Colors.red.shade400),
            title: Text(t.font_size),
            subtitle: Text('${(settings.fontScale * 100).round()}%'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            trailing: SizedBox(
              width: 180,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.red.shade400,
                  thumbColor: Colors.red,
                  overlayColor: Colors.red.withOpacity(0.2),
                ),
                child: Slider(
                  value: settings.fontScale,
                  min: 0.85,
                  max: 1.40,
                  divisions: 11,
                  onChanged: (newValue) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
                      settings.setFontScale(newValue);
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => ListTile(
            leading: Icon(Icons.brightness_6_rounded, color: Colors.red.shade400),
            title: Text(t.theme),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            subtitle: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (m) => m != null ? settings.setThemeMode(m) : null,
            ),
          ),
        ),
        const Divider(height: 1),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => ListTile(
            leading: Icon(Icons.language_rounded, color: Colors.red.shade400),
            title: Text(t.language),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            subtitle: DropdownButton<String>(
              value: settings.locale.languageCode,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (code) => code != null ? settings.setLocale(Locale(code)) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudySection(AppLocalizations t) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => _SectionCard(
        icon: Icons.school_rounded,
        title: 'Học tập',
        iconColor: Colors.blue.shade400,
        children: [
          ListTile(
            leading: Icon(Icons.volume_up_rounded, color: Colors.red.shade400),
            title: Text(t.auto_play),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            trailing: Switch(
              value: settings.autoPlayAudio,
              activeColor: Colors.red,
              onChanged: settings.setAutoPlay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(AppLocalizations t) {
    return _SectionCard(
      icon: Icons.notifications_rounded,
      title: t.daily_reminder,
      iconColor: Colors.orange.shade400,
      children: [
        ListTile(
          leading: Icon(Icons.alarm_rounded, color: Colors.red.shade400),
          title: Text(t.daily_reminder),
          subtitle: Text(_prefs.getString('dailyReminder') ?? t.turn_off),
          trailing: FilledButton.tonal(
            onPressed: () => _pickDailyReminder(),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red.shade700,
            ),
            child: Text(t.pick_time),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
              onPressed: () => _turnOffDailyReminder(),
              label: Text(t.turn_off, style: TextStyle(color: Colors.red.shade400)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDailyReminder() async {
    final t = AppLocalizations.of(context)!;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && mounted) {
      await NotificationService.I.scheduleDaily(picked.hour, picked.minute);
      await _prefs.setString('dailyReminder', '${picked.hour}:${picked.minute}');
      await _prefs.reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${t.daily_reminder}: ${picked.format(context)}'),
              ],
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {}); // Refresh notification section
      }
    }
  }

  Future<void> _turnOffDailyReminder() async {
    final t = AppLocalizations.of(context)!;
    await NotificationService.I.cancelDaily();
    await _prefs.remove('dailyReminder');
    await _prefs.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${t.daily_reminder} • ${t.turn_off}'),
            ],
          ),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {}); // Refresh notification section
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.15)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}