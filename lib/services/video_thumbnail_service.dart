import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Сервис для генерации превью из видео через ffmpeg
class VideoThumbnailService {
  static final VideoThumbnailService _instance = VideoThumbnailService._internal();
  factory VideoThumbnailService() => _instance;
  VideoThumbnailService._internal();

  /// Генерирует превью из первого кадра видео
  /// Возвращает путь к файлу превью или null при ошибке
  Future<String?> generateThumbnail(String videoPath) async {
    try {
      print('[VideoThumbnail] === НАЧАЛО ГЕНЕРАЦИИ ПРЕВЬЮ ===');
      print('[VideoThumbnail] Видео: $videoPath');
      
      // Проверяем существование файла
      final file = File(videoPath);
      if (!await file.exists()) {
        print('[VideoThumbnail] ❌ Файл не найден');
        return null;
      }
      final fileSize = await file.length();
      print('[VideoThumbnail] ✓ Файл существует, размер: ${fileSize ~/ 1024} КБ');

      // Получаем директорию для превью
      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}\\thumbnails');
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }
      print('[VideoThumbnail] ✓ Папка для превью: ${thumbDir.path}');

      // Генерируем имя файла превью
      final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbPath = '${thumbDir.path}\\$fileName';

      // FFmpeg команда для создания превью из первого кадра
      // -ss 00:00:00 - переходим к началу
      // -i input - входной файл
      // -vframes 1 - только 1 кадр
      // -vf scale=400:-1 - масштабируем до 400px по ширине
      // -y - перезаписать если существует
      final ffmpegCommand = '-ss 00:00:01 -i "$videoPath" -vframes 1 -vf scale=400:-1 -y "$thumbPath"';
      
      print('[VideoThumbnail] 🎬 Запуск FFmpeg...');
      print('[VideoThumbnail] Команда: $ffmpegCommand');
      
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        // Проверяем, что файл создан
        final thumbFile = File(thumbPath);
        if (await thumbFile.exists()) {
          final thumbSize = await thumbFile.length();
          print('[VideoThumbnail] ✅ Превью создано: $thumbPath (${thumbSize ~/ 1024} КБ)');
          return thumbPath;
        } else {
          print('[VideoThumbnail] ❌ Файл превью не создан');
        }
      } else {
        final failStackTrace = await session.getFailStackTrace();
        print('[VideoThumbnail] ❌ Ошибка FFmpeg: $failStackTrace');
      }
      
      return null;
    } catch (e, stackTrace) {
      print('[VideoThumbnail] ❌ ИСКЛЮЧЕНИЕ: $e');
      print('[VideoThumbnail] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Очищает папку с превью
  Future<void> cleanupThumbnails() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}\\thumbnails');
      if (await thumbDir.exists()) {
        final files = thumbDir.listSync();
        print('[VideoThumbnail] Удаление ${files.length} файлов превью...');
        await thumbDir.delete(recursive: true);
        print('[VideoThumbnail] ✅ Превью очищены');
      }
    } catch (e) {
      print('[VideoThumbnail] Ошибка очистки: $e');
    }
  }
}
