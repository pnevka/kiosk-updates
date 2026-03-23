import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../utils/constants.dart';

class MediaKitPlayer extends StatefulWidget {
  final String path;
  final bool looping;
  final bool autoPlay;

  const MediaKitPlayer({
    super.key,
    required this.path,
    this.looping = true,
    this.autoPlay = true,
  });

  @override
  State<MediaKitPlayer> createState() => _MediaKitPlayerState();
}

class _MediaKitPlayerState extends State<MediaKitPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isReady = false;
  String? _videoFormat;

  @override
  void initState() {
    super.initState();

    final normalizedPath = widget.path.replaceAll('/', '\\');
    print('[MediaKitPlayer] Путь к видео: ${widget.path}');
    print('[MediaKitPlayer] Нормализованный путь: $normalizedPath');

    final file = File(normalizedPath);
    print('[MediaKitPlayer] Файл существует: ${file.existsSync()}');
    print('[MediaKitPlayer] Размер файла: ${file.lengthSync()} байт');

    if (!file.existsSync()) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Файл не найден';
      });
      return;
    }

    // Инициализируем player
    _player = Player();

    // Инициализируем video controller с отключенным аппаратным ускорением
    // Это решает проблему с Failed to allocate AVHWDeviceContext на некоторых GPU
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        hwdec: 'no', // Отключаем аппаратное декодирование
        enableHardwareAcceleration: false, // Отключаем GPU ускорение
      ),
    );

    // Настраиваем player
    _player.setPlaylistMode(PlaylistMode.loop);

    // Подписываемся на ошибки ДО открытия
    _player.stream.error.listen((error) {
      print('[MediaKitPlayer] Ошибка в потоке: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Ошибка: $error';
        });
      }
    });

    // Подписываемся на состояние плеера
    _player.stream.playing.listen((playing) {
      print('[MediaKitPlayer] Playing: $playing');
    });

    _player.stream.completed.listen((completed) {
      print('[MediaKitPlayer] Completed: $completed');
    });

    // Открываем файл
    _player.open(
      Media(normalizedPath),
    ).then((_) {
      print('[MediaKitPlayer] Видео открыто успешно');
      print('[MediaKitPlayer] State: ${_player.state}');
      print('[MediaKitPlayer] Playing: ${_player.state.playing}');
      print('[MediaKitPlayer] Completed: ${_player.state.completed}');
      
      // Небольшая задержка перед воспроизведением
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _player.play();
          setState(() {
            _isReady = true;
          });
        }
      });
    }).catchError((error) {
      print('[MediaKitPlayer] Ошибка открытия видео: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Ошибка открытия: $error';
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 24),
              Text(
                'Ошибка воспроизведения',
                style: AppTextStyles.screensaverTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: AppTextStyles.screensaverHint.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AbsorbPointer(
      // Поглощаем все касания, чтобы клики не проходили сквозь видео
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(
              controller: _videoController,
              width: double.infinity,
              height: double.infinity,
              controls: NoVideoControls, // Убираем элементы управления
            ),
          ),
        ),
      ),
    );
  }
}
