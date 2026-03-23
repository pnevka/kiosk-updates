import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../models/site_event.dart';

/// Сервис для парсинга афиши с сайта
class SiteEventParser {
  final String baseUrl;
  final String eventsUrl;

  SiteEventParser({
    this.baseUrl = 'https://xn--b1admgmggbb7a6b.xn--p1ai',
    this.eventsUrl = '/meropriyatiya/afisha/',
  });

  /// Парсит мероприятия с сайта
  /// Возвращает список событий или пустой список при ошибке
  Future<List<SiteEvent>> parseEvents() async {
    try {
      final fullUrl = eventsUrl.startsWith('http')
          ? eventsUrl
          : '$baseUrl$eventsUrl';

      print('[SiteEventParser] Загрузка: $fullUrl');

      final response = await http
          .get(
            Uri.parse(fullUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print(
            '[SiteEventParser] Ошибка HTTP: ${response.statusCode}');
        return [];
      }

      final html = response.body;
      final events = _parseHtml(html);

      print('[SiteEventParser] Найдено мероприятий: ${events.length}');
      return events;
    } catch (e) {
      print('[SiteEventParser] Ошибка парсинга: $e');
      return [];
    }
  }

  /// Разбирает HTML и извлекает мероприятия
  List<SiteEvent> _parseHtml(String html) {
    final document = parser.parse(html);
    final events = <SiteEvent>[];
    final seenUrls = <String>{};

    print('[SiteEventParser] Размер HTML: ${html.length} байт');

    // Ищем ВСЕ изображения на странице
    final allImages = document.querySelectorAll('img');
    print('[SiteEventParser] Всего изображений: ${allImages.length}');

    for (final img in allImages) {
      String imageUrl = img.attributes['src'] ?? '';
      if (imageUrl.isEmpty) {
        imageUrl = img.attributes['data-src'] ?? '';
      }
      if (imageUrl.isEmpty) {
        imageUrl = img.attributes['data-lazy-src'] ?? '';
      }
      
      // Пропускаем пустые и уже обработанные
      if (imageUrl.isEmpty || seenUrls.contains(imageUrl)) continue;
      
      // Делаем URL абсолютным
      if (imageUrl.startsWith('/')) {
        imageUrl = '$baseUrl$imageUrl';
      } else if (!imageUrl.startsWith('http')) {
        continue;
      }
      
      seenUrls.add(imageUrl);

      // Пытаемся найти заголовок мероприятия
      String title = _findEventTitle(img);

      // Пытаемся найти ссылку на мероприятие
      String? link = _findEventLink(img);

      // Добавляем только если это похоже на изображение мероприятия
      if (_isEventImage(imageUrl, img)) {
        print('[SiteEventParser] Найдено мероприятие: $title - $imageUrl');
        events.add(SiteEvent(
          imageUrl: imageUrl,
          title: title.isNotEmpty ? title : 'Мероприятие',
          link: link,
        ));
      }
    }

    return events;
  }

  /// Ищет заголовок мероприятия рядом с изображением
  String _findEventTitle(dom.Element img) {
    String title = '';
    dom.Element? parent = img.parent;
    int depth = 0;
    
    while (parent != null && depth < 5) {
      // Ищем заголовки внутри родителя
      final heading = parent.querySelector('h1, h2, h3, h4, h5, .title, .heading, .uk-heading-medium');
      if (heading != null && heading.text.trim().isNotEmpty) {
        title = heading.text.trim();
        break;
      }
      
      // Проверяем следующий элемент после родителя
      dom.Element? next = parent.nextElementSibling;
      if (next != null) {
        final nextHeading = next.querySelector('h1, h2, h3, h4, h5, .title, .heading');
        if (nextHeading != null && nextHeading.text.trim().isNotEmpty) {
          title = nextHeading.text.trim();
          break;
        }
      }
      
      parent = parent.parent;
      depth++;
    }

    // Если не нашли, используем alt
    if (title.isEmpty) {
      title = img.attributes['alt'] ?? img.attributes['title'] ?? '';
    }

    return title;
  }

  /// Ищет ссылку на мероприятие
  String? _findEventLink(dom.Element img) {
    dom.Element? linkElement = _findClosestLink(img);
    if (linkElement != null) {
      String link = linkElement.attributes['href'] ?? '';
      if (link.isNotEmpty && !link.startsWith('http')) {
        return link.startsWith('/') ? '$baseUrl$link' : null;
      }
      return link.isNotEmpty ? link : null;
    }
    return null;
  }

  /// Проверяет, является ли изображение изображением мероприятия
  bool _isEventImage(String imageUrl, dom.Element img) {
    // Пропускаем маленькие изображения (логотипы, иконки)
    final width = int.tryParse(img.attributes['width'] ?? '0') ?? 0;
    final height = int.tryParse(img.attributes['height'] ?? '0') ?? 0;
    
    if (width > 0 && width < 100) return false;
    if (height > 0 && height < 100) return false;
    
    // Пропускаем логотипы
    if (imageUrl.contains('logo')) return false;
    if (img.attributes['alt']?.toLowerCase().contains('logo') ?? false) return false;
    
    // Пропускаем иконки
    if (imageUrl.contains('icon')) return false;
    if (imageUrl.contains('favicon')) return false;
    
    // Пропускаем Яндекс Метрику
    if (imageUrl.contains('metrika')) return false;
    if (imageUrl.contains('yandex')) return false;
    if (imageUrl.contains('mc.yandex')) return false;
    if (img.attributes['alt']?.toLowerCase().contains('metrika') ?? false) return false;
    if (img.attributes['alt']?.toLowerCase().contains('yandex') ?? false) return false;
    
    // Пропускаем изображения из папок analytics, counter, metrics
    if (imageUrl.contains('analytics')) return false;
    if (imageUrl.contains('counter')) return false;
    if (imageUrl.contains('metrics')) return false;
    
    return true;
  }

  /// Ищет ближайший родительский элемент <a>
  dom.Element? _findClosestLink(dom.Element element) {
    dom.Element? parent = element.parent;
    int depth = 0;
    
    while (parent != null && depth < 5) {
      if (parent.localName == 'a') {
        return parent;
      }
      parent = parent.parent;
      depth++;
    }
    
    return null;
  }

  /// Загружает и кэширует изображение
  Future<String?> downloadAndCacheImage(String imageUrl) async {
    try {
      print('[SiteEventParser] Загрузка изображения: $imageUrl');

      final response = await http
          .get(
            Uri.parse(imageUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // TODO: Сохранить в кэш
        return imageUrl; // Пока возвращаем URL
      }

      return null;
    } catch (e) {
      print('[SiteEventParser] Ошибка загрузки изображения: $e');
      return null;
    }
  }
}
