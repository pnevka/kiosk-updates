/// Модель мероприятия с сайта
class SiteEvent {
  final String imageUrl;
  final String title;
  final String? link;

  const SiteEvent({
    required this.imageUrl,
    required this.title,
    this.link,
  });

  /// Пустое событие для проверки
  bool get isEmpty => imageUrl.isEmpty;

  @override
  String toString() => 'SiteEvent(title: $title, imageUrl: $imageUrl)';
}
