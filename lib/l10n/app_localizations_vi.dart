// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get settings_title => 'Cài đặt';

  @override
  String get font_size => 'Cỡ chữ';

  @override
  String get theme => 'Giao diện';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get auto_play => 'Tự phát âm trong màn Học';

  @override
  String get daily_reminder => 'Nhắc hằng ngày';

  @override
  String get pick_time => 'Chọn giờ';

  @override
  String get turn_off => 'Tắt';

  @override
  String get study_play => 'Phát lại';

  @override
  String get settings_hint => 'Các cài đặt này lưu trên thiết bị (SharedPreferences). Bạn có thể đồng bộ lên server ở bước sau.';

  @override
  String get home => 'Trang chủ';

  @override
  String get decks => 'Bộ thẻ';

  @override
  String get learn => 'Học tập';

  @override
  String get profile => 'Hồ sơ';
}
