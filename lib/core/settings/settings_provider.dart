import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _fontScale = 1.0;
  double _animatedFontScale = 1.0;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('vi');
  bool _autoPlayAudio = false;
  bool _animatedAutoPlay = false;
  String _lastKnownRoute = '/home';

  double get fontScale => _fontScale;
  double get animatedFontScale => _animatedFontScale;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get autoPlayAudio => _autoPlayAudio;
  bool get animatedAutoPlay => _animatedAutoPlay;
  String get lastKnownRoute => _lastKnownRoute;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _fontScale = sp.getDouble('fontScale') ?? 1.0;
    _animatedFontScale = _fontScale;
    _themeMode = ThemeMode.values[sp.getInt('themeMode') ?? 0];
    _locale = Locale(sp.getString('locale') ?? 'vi');
    _autoPlayAudio = sp.getBool('autoPlayAudio') ?? false;
    _animatedAutoPlay = _autoPlayAudio;
    _lastKnownRoute = sp.getString('lastKnownRoute') ?? '/home';
    print('SettingsProvider loaded: fontScale=$_fontScale, themeMode=$_themeMode, locale=${_locale.languageCode}, autoPlayAudio=$_autoPlayAudio, lastKnownRoute=$_lastKnownRoute');
  }

  Future<void> _save(void Function(SharedPreferences) edit) async {
    final sp = await SharedPreferences.getInstance();
    edit(sp);
    await sp.reload();
  }

  void setFontScale(double v) {
    final newValue = v.clamp(0.85, 1.40);
    if (newValue != _fontScale) {
      print('Updating fontScale from $_fontScale to $newValue');
      _fontScale = newValue;
      _animatedFontScale = newValue;
      _save((sp) => sp.setDouble('fontScale', _fontScale));
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode m) {
    if (m != _themeMode) {
      print('Updating themeMode to $m');
      _themeMode = m;
      _save((sp) => sp.setInt('themeMode', m.index));
      notifyListeners();
    }
  }

  void setLocale(Locale l) {
    if (l != _locale) {
      print('Updating locale to ${l.languageCode}');
      _locale = l;
      _save((sp) => sp.setString('locale', l.languageCode));
      notifyListeners();
    }
  }

  void setAutoPlay(bool v) {
    if (v != _autoPlayAudio) {
      print('Updating autoPlayAudio to $v');
      _autoPlayAudio = v;
      _animatedAutoPlay = v;
      _save((sp) => sp.setBool('autoPlayAudio', v));
      notifyListeners();
    }
  }

  void setLastKnownRoute(String route) {
    if (route != _lastKnownRoute) {
      print('Updating lastKnownRoute to $route');
      _lastKnownRoute = route;
      _save((sp) => sp.setString('lastKnownRoute', route));
    }
  }
}