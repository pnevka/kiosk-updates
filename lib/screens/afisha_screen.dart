import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../widgets/idle_exit_screen.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';

class AfishaScreen extends StatefulWidget {
  const AfishaScreen({super.key});

  @override
  State<AfishaScreen> createState() => _AfishaScreenState();
}

class _AfishaScreenState extends State<AfishaScreen> with IdleExitMixin<AfishaScreen> {
  final _dataService = DataService();
  final _settingsService = SettingsService();
  List<EventData> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void exitToHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, AppColors.background],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Афиша',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _events.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.event_busy, size: 80, color: AppColors.textSecondary),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Афиша пуста',
                                      style: AppTextStyles.screensaverTitle.copyWith(fontSize: 24),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Здесь появятся мероприятия',
                                      style: AppTextStyles.screensaverHint.copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: _events.length,
                                itemBuilder: (context, index) {
                                  return _buildEventCard(_events[index]);
                                },
                              ),
                  ),
                ],
              ),
            ),
            // Glass back button at bottom center
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Назад',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventData event) {
    return GestureDetector(
      onTap: () => _openEventDetail(event),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (event.imagePath.isNotEmpty)
                _buildEventImage(event.imagePath)
              else
                Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.image, size: 48, color: AppColors.textSecondary),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 0.8],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventImage(String imagePath) {
    // Проверяем, это URL (с сайта) или локальный файл
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Это URL с сайта — скачиваем и кэшируем
      return FutureBuilder<File>(
        future: _downloadAndCacheImage(imagePath),
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
            return Container(
              color: AppColors.surface,
              child: const Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary),
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
        return Container(
          color: AppColors.surface,
          child: const Icon(Icons.image, size: 48, color: AppColors.textSecondary),
        );
      }
    }
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

// Event detail screen with full screen photo
class EventDetailScreen extends StatefulWidget {
  final EventData event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with IdleExitMixin<EventDetailScreen> {
  @override
  void exitToHome(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        resetIdleTimer();
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Full screen photo only
            Positioned.fill(
              child: Center(
                child: _buildEventImage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    final imagePath = widget.event.imagePath;

    if (imagePath.isEmpty) {
      return Container(
        color: AppColors.surface,
        child: const Icon(Icons.image, size: 100, color: AppColors.textSecondary),
      );
    }

    // Проверяем, это URL (с сайта) или локальный файл
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Это URL с сайта — используем кэш
      return FutureBuilder<File>(
        future: _downloadAndCacheImage(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Icon(Icons.broken_image, size: 100, color: AppColors.textSecondary),
            );
          }
          
          final file = snapshot.data!;
          return Image.file(
            file,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            width: double.infinity,
            height: double.infinity,
          );
        },
      );
    } else {
      // Это локальный файл
      final file = File(imagePath);
      if (file.existsSync()) {
        return PhotoView(
          imageProvider: FileImage(file),
          minScale: PhotoViewComputedScale.covered,
          maxScale: PhotoViewComputedScale.covered * 2,
        );
      } else {
        return Container(
          color: AppColors.surface,
          child: const Icon(Icons.image, size: 100, color: AppColors.textSecondary),
        );
      }
    }
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
