class AdminEvent {
  final String id;
  final String title;
  final String? description;
  final String imagePath;
  final DateTime date;
  final String location;

  AdminEvent({
    required this.id,
    required this.title,
    this.description,
    required this.imagePath,
    required this.date,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'location': location,
    };
  }

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    return AdminEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imagePath: json['imagePath'] ?? '',
      date: DateTime.parse(json['date']),
      location: json['location'] ?? '',
    );
  }
}

class CircleData {
  final String id;
  final String title;
  final String? description;
  final String? schedule;
  final String? location;
  final String? price;
  final String? age;
  final String imagePath;
  final String? qrImagePath;
  final String? instructor; // Руководитель
  final String? whatYouLearn; // Чему вы научитесь
  bool isEnabled;

  CircleData({
    required this.id,
    required this.title,
    this.description,
    this.schedule,
    this.location,
    this.price,
    this.age,
    required this.imagePath,
    this.qrImagePath,
    this.instructor,
    this.whatYouLearn,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'schedule': schedule,
      'location': location,
      'price': price,
      'age': age,
      'imagePath': imagePath,
      'qrImagePath': qrImagePath,
      'instructor': instructor,
      'whatYouLearn': whatYouLearn,
      'isEnabled': isEnabled,
    };
  }

  factory CircleData.fromJson(Map<String, dynamic> json) {
    return CircleData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      schedule: json['schedule'],
      location: json['location'],
      price: json['price'],
      age: json['age'],
      imagePath: json['imagePath'] ?? '',
      qrImagePath: json['qrImagePath'],
      instructor: json['instructor'],
      whatYouLearn: json['whatYouLearn'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

class AlbumData {
  final String id;
  final String title;
  final String? description;
  final String? coverImagePath;
  final List<MediaData> media;
  bool isEnabled;

  AlbumData({
    required this.id,
    required this.title,
    this.description,
    this.coverImagePath,
    this.media = const [],
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImagePath': coverImagePath,
      'media': media.map((m) => m.toJson()).toList(),
      'isEnabled': isEnabled,
    };
  }

  factory AlbumData.fromJson(Map<String, dynamic> json) {
    return AlbumData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      coverImagePath: json['coverImagePath'],
      media: (json['media'] as List<dynamic>?)?.map((m) => MediaData.fromJson(m)).toList() ?? [],
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

class MediaData {
  final String id;
  final String filePath;
  final bool isVideo;
  final String? title;
  final String? thumbnailPath; // Путь к превью для видео
  final DateTime createdAt;

  MediaData({
    required this.id,
    required this.filePath,
    required this.isVideo,
    this.title,
    this.thumbnailPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'isVideo': isVideo,
      'title': title,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MediaData.fromJson(Map<String, dynamic> json) {
    return MediaData(
      id: json['id'] ?? '',
      filePath: json['filePath'] ?? '',
      isVideo: json['isVideo'] ?? false,
      title: json['title'],
      thumbnailPath: json['thumbnailPath'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class AdminGalleryItem {
  final String id;
  final String title;
  final String filePath;
  final bool isVideo;
  final DateTime createdAt;

  AdminGalleryItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.isVideo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'isVideo': isVideo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdminGalleryItem.fromJson(Map<String, dynamic> json) {
    return AdminGalleryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      filePath: json['filePath'] ?? '',
      isVideo: json['isVideo'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
