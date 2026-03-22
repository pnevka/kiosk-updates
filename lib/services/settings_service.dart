import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  String? adminPassword;
  bool slideshowEnabled;
  int slideshowInterval; // in seconds
  int idleTimeout; // seconds before slideshow starts on idle

  AppSettings({
    this.adminPassword,
    this.slideshowEnabled = false,
    this.slideshowInterval = 30,
    this.idleTimeout = 60,
  });

  Map<String, dynamic> toJson() {
    return {
      'adminPassword': adminPassword,
      'slideshowEnabled': slideshowEnabled,
      'slideshowInterval': slideshowInterval,
      'idleTimeout': idleTimeout,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      adminPassword: json['adminPassword'],
      slideshowEnabled: json['slideshowEnabled'] ?? false,
      slideshowInterval: json['slideshowInterval'] ?? 30,
      idleTimeout: json['idleTimeout'] ?? 60,
    );
  }
}

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  AppSettings _settings = AppSettings();
  bool _isLoaded = false;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _settingsFile async {
    final path = await _localPath;
    return File('$path/settings.json');
  }

  Future<AppSettings> loadSettings() async {
    if (_isLoaded) return _settings;

    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents);
        _settings = AppSettings.fromJson(json);
      }
    } catch (e) {
      print('Error loading settings: $e');
      _settings = AppSettings();
    }

    _isLoaded = true;
    return _settings;
  }

  Future<void> saveSettings() async {
    try {
      final file = await _settingsFile;
      await file.writeAsString(jsonEncode(_settings.toJson()));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> setPassword(String? password) async {
    _settings.adminPassword = password;
    await saveSettings();
  }

  bool checkPassword(String password) {
    if (_settings.adminPassword == null) return true;
    return _settings.adminPassword == password;
  }

  Future<void> setSlideshowEnabled(bool enabled) async {
    _settings.slideshowEnabled = enabled;
    await saveSettings();
  }

  Future<void> setSlideshowInterval(int seconds) async {
    _settings.slideshowInterval = seconds;
    await saveSettings();
  }

  Future<void> setIdleTimeout(int seconds) async {
    _settings.idleTimeout = seconds;
    await saveSettings();
  }

  AppSettings get settings => _settings;
}
