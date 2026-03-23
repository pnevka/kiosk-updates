import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/admin_content.dart';
import '../models/site_event.dart';
import 'site_event_parser.dart';
import 'package:crypto/crypto.dart';

class EventData {
  final String id;
  final String title;
  final String? description;
  final String imagePath;
  final DateTime date;
  final String location;
  bool isEnabled;

  EventData({
    required this.id,
    required this.title,
    this.description,
    required this.imagePath,
    required this.date,
    required this.location,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'location': location,
      'isEnabled': isEnabled,
    };
  }

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? '',
      description: json['description'],
      imagePath: json['imagePath'] ?? '',
      date: DateTime.parse(json['date']),
      location: json['location'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<EventData> _events = [];
  List<CircleData> _circles = [];
  bool _isLoaded = false;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _eventsFile async {
    final path = await _localPath;
    return File('$path/events.json');
  }

  Future<File> get _circlesFile async {
    final path = await _localPath;
    return File('$path/circles.json');
  }

  // Events
  Future<List<EventData>> loadEvents() async {
    if (_isLoaded) return _events;

    try {
      final file = await _eventsFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        _events = jsonList.map((json) => EventData.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading events: $e');
      _events = [];
    }

    _isLoaded = true;
    return _events;
  }

  Future<void> saveEvents() async {
    try {
      final file = await _eventsFile;
      final jsonList = _events.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving events: $e');
    }
  }

  Future<void> addEvent(EventData event) async {
    _events.add(event);
    await saveEvents();
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await saveEvents();
  }

  Future<void> toggleEvent(String id) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index].isEnabled = !_events[index].isEnabled;
      await saveEvents();
    }
  }

  List<EventData> getEnabledEvents() {
    return _events.where((e) => e.isEnabled).toList();
  }

  // Circles
  Future<List<CircleData>> loadCircles() async {
    try {
      final file = await _circlesFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        _circles = jsonList.map((json) => CircleData.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading circles: $e');
      _circles = [];
    }
    return _circles;
  }

  Future<void> saveCircles() async {
    try {
      final file = await _circlesFile;
      final jsonList = _circles.map((c) => c.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving circles: $e');
    }
  }

  Future<void> addCircle(CircleData circle) async {
    _circles.add(circle);
    await saveCircles();
  }

  Future<void> deleteCircle(String id) async {
    _circles.removeWhere((c) => c.id == id);
    await saveCircles();
  }

  Future<void> toggleCircle(String id) async {
    final index = _circles.indexWhere((c) => c.id == id);
    if (index != -1) {
      _circles[index].isEnabled = !_circles[index].isEnabled;
      await saveCircles();
    }
  }

  List<CircleData> getEnabledCircles() {
    return _circles.where((c) => c.isEnabled).toList();
  }

  // Albums
  List<AlbumData> _albums = [];

  Future<File> get _albumsFile async {
    final path = await _localPath;
    return File('$path/albums.json');
  }

  Future<List<AlbumData>> loadAlbums() async {
    try {
      final file = await _albumsFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        _albums = jsonList.map((json) => AlbumData.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading albums: $e');
      _albums = [];
    }
    return _albums;
  }

  Future<void> saveAlbums() async {
    try {
      final file = await _albumsFile;
      final jsonList = _albums.map((a) => a.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving albums: $e');
    }
  }

  Future<void> addAlbum(AlbumData album) async {
    _albums.add(album);
    await saveAlbums();
  }

  Future<void> updateAlbum(AlbumData album) async {
    final index = _albums.indexWhere((a) => a.id == album.id);
    if (index != -1) {
      _albums[index] = album;
      await saveAlbums();
    }
  }

  Future<void> deleteAlbum(String id) async {
    _albums.removeWhere((a) => a.id == id);
    await saveAlbums();
  }

  Future<void> toggleAlbum(String id) async {
    final index = _albums.indexWhere((a) => a.id == id);
    if (index != -1) {
      _albums[index].isEnabled = !_albums[index].isEnabled;
      await saveAlbums();
    }
  }

  List<AlbumData> getEnabledAlbums() {
    return _albums.where((a) => a.isEnabled).toList();
  }

  Future<void> addMediaToAlbum(String albumId, MediaData media) async {
    final index = _albums.indexWhere((a) => a.id == albumId);
    if (index != -1) {
      final updatedMedia = List<MediaData>.from(_albums[index].media)..add(media);
      final updatedAlbum = AlbumData(
        id: _albums[index].id,
        title: _albums[index].title,
        description: _albums[index].description,
        coverImagePath: _albums[index].coverImagePath,
        media: updatedMedia,
        isEnabled: _albums[index].isEnabled,
      );
      _albums[index] = updatedAlbum;
      await saveAlbums();
    }
  }

  Future<void> removeMediaFromAlbum(String albumId, String mediaId) async {
    final index = _albums.indexWhere((a) => a.id == albumId);
    if (index != -1) {
      final updatedMedia = _albums[index].media.where((m) => m.id != mediaId).toList();
      final updatedAlbum = AlbumData(
        id: _albums[index].id,
        title: _albums[index].title,
        description: _albums[index].description,
        coverImagePath: _albums[index].coverImagePath,
        media: updatedMedia,
        isEnabled: _albums[index].isEnabled,
      );
      _albums[index] = updatedAlbum;
      await saveAlbums();
    }
  }

  // Site events parsing
  List<EventData> _siteEvents = [];

  /// Загружает афишу с сайта
  /// Если enableSiteParsing = false, возвращает локальные события
  Future<List<EventData>> loadSiteEvents({
    required bool enableSiteParsing,
    required String siteUrl,
  }) async {
    if (!enableSiteParsing) {
      // Парсинг отключён — возвращаем локальные события
      return getEnabledEvents();
    }

    try {
      final parser = SiteEventParser(eventsUrl: siteUrl);
      final siteEvents = await parser.parseEvents();

      if (siteEvents.isEmpty) {
        print('[DataService] Сайт недоступен или пуст — используем локальные события');
        return getEnabledEvents();
      }

      // Конвертируем SiteEvent в EventData
      _siteEvents = siteEvents.map((siteEvent) {
        return EventData(
          id: const Uuid().v4(),
          title: siteEvent.title.isNotEmpty ? siteEvent.title : 'Мероприятие',
          description: null,
          imagePath: siteEvent.imageUrl, // URL картинки вместо локального пути
          date: DateTime.now(), // Дата будет взята из сайта позже (если нужно)
          location: '',
          isEnabled: true,
        );
      }).toList();

      print('[DataService] Загружено ${_siteEvents.length} мероприятий с сайта');
      
      // Очищаем кэш — удаляем старые изображения
      await _cleanupAfishaCache(_siteEvents);
      
      return _siteEvents;
    } catch (e) {
      print('[DataService] Ошибка загрузки с сайта: $e — используем локальные события');
      return getEnabledEvents();
    }
  }

  /// Очищает кэш афиши — удаляет файлы, которых нет в текущем списке
  Future<void> _cleanupAfishaCache(List<EventData> currentEvents) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/afisha_cache');
      
      if (!await cacheDir.exists()) {
        return;
      }

      // Получаем список текущих URL
      final currentUrls = currentEvents
          .where((e) => e.imagePath.startsWith('http'))
          .map((e) => e.imagePath)
          .toSet();

      // Получаем список файлов в кэше
      final files = cacheDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final fileName = file.uri.pathSegments.last;
          final fileHash = fileName.replaceAll('.jpg', '');
          
          // Проверяем, есть ли файл в текущих URL
          bool isStillUsed = false;
          for (final url in currentUrls) {
            final hash = md5.convert(utf8.encode(url)).toString();
            if (hash == fileHash) {
              isStillUsed = true;
              break;
            }
          }
          
          // Если файл больше не используется — удаляем
          if (!isStillUsed) {
            await file.delete();
            print('[DataService] Удалён устаревший кэш: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('[DataService] Ошибка очистки кэша: $e');
    }
  }

  /// Возвращает последние загруженные события с сайта
  List<EventData> getSiteEvents() {
    return _siteEvents;
  }
}
