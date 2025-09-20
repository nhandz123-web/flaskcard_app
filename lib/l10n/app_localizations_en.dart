// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings_title => 'Settings';

  @override
  String get font_size => 'Font size';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get auto_play => 'Auto-play audio in Study';

  @override
  String get daily_reminder => 'Daily reminder';

  @override
  String get pick_time => 'Pick time';

  @override
  String get turn_off => 'Turn off';

  @override
  String get study_play => 'Play';

  @override
  String get settings_hint => 'These settings are saved on device (SharedPreferences). You can sync to server later.';

  @override
  String get home => 'Home';

  @override
  String get decks => 'Decks';

  @override
  String get learn => 'Learn';

  @override
  String get profile => 'Profile';
}
