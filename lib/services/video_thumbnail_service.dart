import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Сервис для генерации превью из видео
class VideoThumbnailService {
  static final VideoThumbnailService _instance = VideoThumbnailService._internal();
  factory VideoThumbnailService() => _instance;
  VideoThumbnailService._internal();

  /// Генерирует превью из первого кадра видео
  /// Возвращает путь к файлу превью или null при ошибке
  Future<String?> generateThumbnail(String videoPath) async {
    try {
      print('[VideoThumbnail] Генерация превью для: $videoPath');
      
      // Проверяем существование файла
      final file = File(videoPath);
      if (!await file.exists()) {
        print('[VideoThumbnail] Файл не найден');
        return null;
      }

      // Получаем директорию для превью
      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}\\thumbnails');
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      // Генерируем имя файла превью
      final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbPath = '${thumbDir.path}\\$fileName';

      // Генерируем превью из первого кадра (0 секунд)
      final thumbnail = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 80, // Качество JPEG
        position: -1, // -1 = первый кадр
      );

      if (thumbnail != null) {
        // Сохраняем превью
        final thumbFile = File(thumbPath);
        await thumbFile.writeAsBytes(await thumbnail.readAsBytes());
        print('[VideoThumbnail] Превью сохранено: $thumbPath');
        return thumbPath;
      } else {
        print('[VideoThumbnail] Не удалось создать превью');
        return null;
      }
    } catch (e) {
      print('[VideoThumbnail] Ошибка: $e');
      return null;
    }
  }

  /// Очищает папку с превью
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
