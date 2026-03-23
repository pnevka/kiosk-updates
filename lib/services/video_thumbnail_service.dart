import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Сервис-заглушка для превью видео
/// На Windows генерация превью не поддерживается
class VideoThumbnailService {
  static final VideoThumbnailService _instance = VideoThumbnailService._internal();
  factory VideoThumbnailService() => _instance;
  VideoThumbnailService._internal();

  /// Возвращает null — превью не создаётся
  Future<String?> generateThumbnail(String videoPath) async {
    print('[VideoThumbnail] Превью для видео не создаётся (Windows не поддерживает)');
    return null;
  }

  /// Очищает папку с превью (если была)
  Future<void> cleanupThumbnails() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}\\thumbnails');
      if (await thumbDir.exists()) {
        await thumbDir.delete(recursive: true);
        print('[VideoThumbnail] Превью очищены');
      }
    } catch (e) {
      print('[VideoThumbnail] Ошибка очистки: $e');
    }
  }
}
