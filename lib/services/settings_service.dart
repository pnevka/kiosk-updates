import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AppSettings {
  String? adminPassword;
  bool slideshowEnabled;
  int slideshowInterval; // in seconds
  int idleTimeout; // seconds before slideshow starts on idle
  bool enableSiteParsing; // парсинг афиши с сайта
  String siteEventsUrl; // URL страницы афиши
  int idleExitTimeout; // секунды до возврата на главную при бездействии
  bool autoStart; // автозапуск при загрузке Windows

  AppSettings({
    this.adminPassword,
    this.slideshowEnabled = false,
    this.slideshowInterval = 30,
    this.idleTimeout = 60,
    this.enableSiteParsing = false,
    this.siteEventsUrl = '/afisha/',
    this.idleExitTimeout = 180, // 3 минуты по умолчанию
    this.autoStart = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'adminPassword': adminPassword,
      'slideshowEnabled': slideshowEnabled,
      'slideshowInterval': slideshowInterval,
      'idleTimeout': idleTimeout,
      'enableSiteParsing': enableSiteParsing,
      'siteEventsUrl': siteEventsUrl,
      'idleExitTimeout': idleExitTimeout,
      'autoStart': autoStart,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      adminPassword: json['adminPassword'],
      slideshowEnabled: json['slideshowEnabled'] ?? false,
      slideshowInterval: json['slideshowInterval'] ?? 30,
      idleTimeout: json['idleTimeout'] ?? 60,
      enableSiteParsing: json['enableSiteParsing'] ?? false,
      siteEventsUrl: json['siteEventsUrl'] ?? '/afisha/',
      idleExitTimeout: json['idleExitTimeout'] ?? 180,
      autoStart: json['autoStart'] ?? false,
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

  Future<void> setEnableSiteParsing(bool enabled) async {
    _settings.enableSiteParsing = enabled;
    await saveSettings();
  }

  Future<void> setSiteEventsUrl(String url) async {
    _settings.siteEventsUrl = url;
    await saveSettings();
  }

  Future<void> setIdleExitTimeout(int seconds) async {
    _settings.idleExitTimeout = seconds;
    await saveSettings();
  }

  Future<void> setAutoStart(bool enabled) async {
    _settings.autoStart = enabled;
    await saveSettings();
    
    // Добавляем/удаляем ярлык в автозагрузку Windows
    if (Platform.isWindows) {
      await _updateWindowsAutoStart(enabled);
    }
  }

  Future<void> _updateWindowsAutoStart(bool enabled) async {
    try {
      // Путь к папке автозагрузки
      final appData = await getApplicationDocumentsDirectory();
      final exePath = Platform.resolvedExecutable;
      final shortcutPath = '${appData.path}\\..\\..\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\kiosk.lnk';
      
      if (enabled) {
        // Создаем ярлык в автозагрузке через PowerShell
        final psScript = '''
        \$WshShell = New-Object -comObject WScript.Shell
        \$Shortcut = \$WshShell.CreateShortcut("$shortcutPath")
        \$Shortcut.TargetPath = "$exePath"
        \$Shortcut.Save()
        ''';
        await Process.run('powershell', ['-Command', psScript]);
        print('[SettingsService] Автозапуск включен: $shortcutPath');
      } else {
        // Удаляем ярлык
        final file = File(shortcutPath);
        if (await file.exists()) {
          await file.delete();
          print('[SettingsService] Автозапуск выключен');
        }
      }
    } catch (e) {
      print('[SettingsService] Ошибка настройки автозапуска: $e');
    }
  }

  AppSettings get settings => _settings;
}
