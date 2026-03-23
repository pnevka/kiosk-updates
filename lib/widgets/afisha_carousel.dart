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
    super.dispose();
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
    print('[AfishaCarousel] Загрузка изображения: $imagePath');
    
    // Проверяем, это URL (с сайта) или локальный файл
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Это URL с сайта — скачиваем и кэшируем
      return _buildCachedImage(imagePath);
    } else {
      // Это локальный файл
      final file = File(imagePath);
      if (file.existsSync()) {
        return Positioned.fill(
          child: Image.file(
            file,
            fit: BoxFit.cover,
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

  Widget _buildCachedImage(String imageUrl) {
    return FutureBuilder<File>(
      future: _downloadAndCacheImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          print('[AfishaCarousel] Ошибка загрузки: ${snapshot.error}');
          return Container(
            color: Colors.black12,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text('Ошибка загрузки', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        }
        
        final file = snapshot.data!;
        return Positioned.fill(
          child: Image.file(
            file,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }

  Future<File> _downloadAndCacheImage(String imageUrl) async {
    // Генерируем имя файла из URL
    final hash = md5.convert(utf8.encode(imageUrl));
    final fileName = '${hash.toString()}.jpg';
    
    // Получаем директорию для кэша
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/afisha_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    final cachedFile = File('${cacheDir.path}/$fileName');
    
    // Если файл уже есть в кэше — возвращаем его
    if (await cachedFile.exists()) {
      return cachedFile;
    }
    
    // Скачиваем изображение
    final response = await http
        .get(
          Uri.parse(imageUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Referer': 'https://xn--b1admgmggbb7a6b.xn--p1ai/',
          },
        )
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      await cachedFile.writeAsBytes(response.bodyBytes);
      return cachedFile;
    }
    
    throw Exception('HTTP ${response.statusCode}');
  }
}
