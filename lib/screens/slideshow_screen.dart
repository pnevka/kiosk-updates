import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _videoController;
  bool _isVideo = false;

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
    final settings = _settingsService.settings;
    
    _showCurrentMedia();
    
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(
      Duration(seconds: settings.slideshowInterval),
      (_) => _nextSlide(),
    );
  }

  void _showCurrentMedia() {
    if (_media.isEmpty) return;
    
    final media = _media[_currentIndex % _media.length];
    
    setState(() {
      _isVideo = media.isVideo;
    });
    
    if (media.isVideo) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(media.filePath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });
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
    _videoController?.dispose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _videoController?.dispose();
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
              child: _isVideo && _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : _media.isNotEmpty
                      ? PhotoView(
                          imageProvider: FileImage(File(_media[_currentIndex % _media.length].filePath)),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        )
                      : Container(),
            ),
            // Exit hint (fades in after 2 seconds)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Коснитесь для выхода',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
