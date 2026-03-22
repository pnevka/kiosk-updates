import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:archive/archive_io.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // GitHub Releases API
  // Репозиторий: https://github.com/pnevka/kiosk-updates
  static const String _githubUser = 'pnevka';
  static const String _githubRepo = 'kiosk-updates';
  
  static String get _updateUrl => 
    'https://api.github.com/repos/$_githubUser/$_githubRepo/releases/latest';

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_updateUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"error": "timeout"}', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentVersion = await getCurrentVersion();
        final latestVersion = data['tag_name'] as String;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          // Ищем файл для Windows
          String downloadUrl = '';
          for (var asset in data['assets'] as List) {
            if (asset['name'].toString().endsWith('.zip') || 
                asset['name'].toString().endsWith('.exe')) {
              downloadUrl = asset['browser_download_url'] as String;
              break;
            }
          }
          
          return {
            'version': latestVersion,
            'description': data['body'] ?? '',
            'downloadUrl': downloadUrl,
          };
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  Future<bool> downloadAndInstall(String downloadUrl, Function(double) onProgress) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl)).timeout(
        const Duration(minutes: 5),
        onTimeout: () => http.Response('error', 408),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        
        // Определяем тип файла
        final isZip = downloadUrl.endsWith('.zip');
        final fileName = isZip ? 'kiosk_update.zip' : 'kiosk_installer.exe';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        // Сохраняем файл
        await file.writeAsBytes(response.bodyBytes);
        
        if (Platform.isWindows) {
          if (isZip) {
            // Распаковываем ZIP
            final bytes = await file.readAsBytes();
            final archive = ZipDecoder().decodeBytes(bytes);
            
            // Находим exe файл в архиве и запускаем
            for (var file in archive) {
              if (file.name.endsWith('.exe')) {
                final exePath = '${directory.path}/${file.name}';
                final exeFile = File(exePath);
                await exeFile.writeAsBytes(file.content as List<int>);
                
                // Запуск установщика
                await Process.start(exePath, []);
                exit(0);
              }
            }
          } else {
            // Запускаем exe напрямую
            await Process.start(filePath, []);
            exit(0);
          }
        }
        return true;
      }
    } catch (e) {
      print('Error downloading update: $e');
    }
    return false;
  }

  Future<void> openDownloadPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
