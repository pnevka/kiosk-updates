import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../screens/afisha_screen.dart';

class AfishaCarousel extends StatefulWidget {
  const AfishaCarousel({super.key});

  @override
  State<AfishaCarousel> createState() => _AfishaCarouselState();
}

class _AfishaCarouselState extends State<AfishaCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  final _dataService = DataService();
  final _settingsService = SettingsService();
  List<EventData> _events = [];
  bool _isLoading = true;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.35, initialPage: 50);
    _loadEvents();
  }

  @override
  void didUpdateWidget(AfishaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final settings = await _settingsService.loadSettings();
    
    // Загружаем афишу с сайта или локальные события
    final events = await _dataService.loadSiteEvents(
      enableSiteParsing: settings.enableSiteParsing,
      siteUrl: settings.siteEventsUrl,
    );
    
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (_events.isEmpty) return;

    _timer?.cancel();
    // Start scrolling after a delay
    _timer = Timer.periodic(AppDurations.carouselInterval, (timer) {
      if (_pageController.hasClients && _events.isNotEmpty) {
        // Always scroll to next page (no wrapping needed with large itemCount)
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    // Очищаем кэш афиши при выходе
    _cleanupCache();
    super.dispose();
  }

  Future<void> _cleanupCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/afisha_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('[AfishaCarousel] Кэш очищен');
      }
    } catch (e) {
      print('[AfishaCarousel] Ошибка очистки кэша: $e');
    }
  }

  void _openEventDetail(EventData event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_events.isEmpty) {
      return SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Афиша пуста',
                style: AppTextStyles.screensaverHint.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _events.length * 100,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % _events.length;
              });
            },
            itemBuilder: (context, index) {
              return _buildEventCard(_events[index % _events.length], index % _events.length, constraints.maxHeight);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventData event, int index, double carouselHeight) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          final currentPage = _pageController.page!;
          value = currentPage - index;
          value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            width: carouselHeight * 0.56, // 9:16 aspect ratio
            height: carouselHeight * 0.95,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _openEventDetail(event),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            color: Colors.transparent,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            child: Stack(
              children: [
                if (event.imagePath.isNotEmpty)
                  _buildImage(event.imagePath)
                else
                  Container(
                    color: Colors.transparent,
                    child: const Icon(Icons.image, size: 64, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    // Теперь все изображения локальные - используем Image.file
    final file = File(imagePath);
    if (file.existsSync()) {
      return Positioned.fill(
        child: Image.file(
          file,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    } else {
      print('[AfishaCarousel] Файл не найден: $imagePath');
      return Container(
        color: Colors.transparent,
        child: const Icon(Icons.image, size: 64, color: AppColors.textSecondary),
      );
    }
  }
}
