class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? imageUrl;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl,
    required this.location,
  });
}
