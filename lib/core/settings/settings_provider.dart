import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _fontScale = 1.0;
  double _animatedFontScale = 1.0; // Cho slider font
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('vi');
  bool _autoPlayAudio = false;
  bool _animatedAutoPlay = false; // Cho nút tự phát

  double get fontScale => _fontScale;
  double get animatedFontScale => _animatedFontScale;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get autoPlayAudio => _autoPlayAudio;
  bool get animatedAutoPlay => _animatedAutoPlay;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _fontScale = sp.getDouble('fontScale') ?? 1.0;
    _animatedFontScale = _fontScale;
    _themeMode = ThemeMode.values[sp.getInt('themeMode') ?? 0];
    _locale = Locale(sp.getString('locale') ?? 'vi');
    _autoPlayAudio = sp.getBool('autoPlayAudio') ?? false;
    _animatedAutoPlay = _autoPlayAudio; // Đồng bộ ban đầu
    notifyListeners();
  }

  Future<void> _save(void Function(SharedPreferences) edit) async {
    final sp = await SharedPreferences.getInstance();
    edit(sp);
    await Future.delayed(const Duration(milliseconds: 100)); // Delay để tránh issue
    notifyListeners();
  }

  void setFontScale(double v) {
    final newValue = v.clamp(0.85, 1.40);
    if (newValue != _fontScale) {
      _fontScale = newValue;
      _animatedFontScale = newValue;
      _save((sp) => sp.setDouble('fontScale', _fontScale));
    }
  }

  void setThemeMode(ThemeMode m) {
    if (m != _themeMode) {
      _themeMode = m;
      _save((sp) => sp.setInt('themeMode', m.index));
    }
  }

  void setLocale(Locale l) {
    if (l != _locale) {
      _locale = l;
      _save((sp) => sp.setString('locale', l.languageCode));
    }
  }

  void setAutoPlay(bool v) {
    if (v != _autoPlayAudio) {
      _autoPlayAudio = v;
      _animatedAutoPlay = v; // Cập nhật giá trị animation
      _save((sp) => sp.setBool('autoPlayAudio', v));
    }
  }
}