import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../models/admin_content.dart';

class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  final _dataService = DataService();
  final _settingsService = SettingsService();
  List<MediaData> _media = [];
  int _currentIndex = 0;
  Timer? _slideshowTimer;
  Player? _player;
  VideoController? _videoController;
  bool _isVideo = false;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final albums = await _dataService.loadAlbums();
    final allMedia = <MediaData>[];

    for (final album in albums) {
      if (album.isEnabled) {
        allMedia.addAll(album.media);
      }
    }

    // Shuffle media
    allMedia.shuffle(Random());

    setState(() {
      _media = allMedia;
    });

    if (_media.isNotEmpty) {
      _startSlideshow();
    }
  }

  void _startSlideshow() {
    _showCurrentMedia();
  }

  void _startSlideTimer() {
    final settings = _settingsService.settings;

    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(
      Duration(seconds: settings.slideshowInterval),
      (_) {
        if (!_isVideoPlaying) {
          _nextSlide();
        }
      },
    );
  }

  void _showCurrentMedia() {
    if (_media.isEmpty) return;

    final media = _media[_currentIndex % _media.length];

    setState(() {
      _isVideo = media.isVideo;
      _isVideoPlaying = media.isVideo;
    });

    if (media.isVideo) {
      // Для видео не используем таймер - ждём завершения
      _slideshowTimer?.cancel();

      // Очищаем старый плеер
      _player?.stop();
      _player?.dispose();
      _player = null;
      _videoController = null;
      setState(() {});

      // Создаем новый плеер
      _player = Player();

      _videoController = VideoController(
        _player!,
        configuration: const VideoControllerConfiguration(
          hwdec: 'no', // Отключаем аппаратное декодирование
          enableHardwareAcceleration: false, // Отключаем GPU ускорение
        ),
      );

      // НЕ зацикливаем видео - играем один раз
      _player!.setPlaylistMode(PlaylistMode.single);

      // Подписываемся на завершение видео
      _player!.stream.completed.listen((completed) {
        print('[Slideshow] Видео завершено: $completed');
        if (completed && mounted) {
          setState(() {
            _isVideoPlaying = false;
          });
          // Переключаем на следующий слайд после завершения видео
          _nextSlide();
        }
      });

      _player!.stream.error.listen((error) {
        print('[Slideshow] Ошибка видео: $error');
        if (mounted) {
          setState(() {
            _isVideoPlaying = false;
          });
          _nextSlide();
        }
      });

      _player!.open(Media(media.filePath)).then((_) {
        print('[Slideshow] Видео открыто');
        _player!.play();
      }).catchError((error) {
        print('[Slideshow] Ошибка открытия видео: $error');
        if (mounted) {
          setState(() {
            _isVideoPlaying = false;
          });
          _nextSlide();
        }
      });
    } else {
      // Для фото используем таймер
      _startSlideTimer();
    }
  }

  void _nextSlide() {
    setState(() {
      _currentIndex++;
    });
    _showCurrentMedia();
  }

  void _exitSlideshow() {
    _slideshowTimer?.cancel();
    _player?.stop();
    _player?.dispose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    // Сначала останавливаем воспроизведение
    _player?.stop();
    // Затем освобождаем ресурсы
    _player?.dispose();
    _player = null;
    _videoController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_media.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'Загрузка слайд-шоу...',
                style: AppTextStyles.screensaverHint.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _exitSlideshow,
        child: Stack(
          children: [
            // Content
            Center(
              child: _isVideo && _videoController != null
                  ? Video(
                      controller: _videoController!,
                      width: double.infinity,
                      height: double.infinity,
                      controls: NoVideoControls, // Убираем элементы управления
                    )
                  : _media.isNotEmpty
                      ? PhotoView(
                          imageProvider: FileImage(File(_media[_currentIndex % _media.length].filePath)),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        )
                      : Container(),
            ),
          ],
        ),
      ),
    );
  }
}
