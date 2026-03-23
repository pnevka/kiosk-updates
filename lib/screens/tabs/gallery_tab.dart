import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';
import '../../services/data_service.dart';
import '../../models/admin_content.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> with SingleTickerProviderStateMixin {
  final _dataService = DataService();
  late TabController _tabController;
  List<AlbumData> _albums = [];
  bool _isLoading = true;
  
  // New album form
  final _albumTitleController = TextEditingController();
  final _albumDescController = TextEditingController();
  String? _albumCoverPath;
  
  // Media picker
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    await _dataService.loadAlbums();
    if (mounted) {
      setState(() {
        _albums = _dataService.getEnabledAlbums();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAlbumCover() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() {
          _albumCoverPath = image.path;
        });
      }
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  Future<void> _createAlbum() async {
    if (_albumTitleController.text.isEmpty) {
      _showError('Введите название альбома');
      return;
    }

    try {
      String? coverPath;
      if (_albumCoverPath != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final albumsDir = Directory('${appDir.path}/albums');
        if (!await albumsDir.exists()) {
          await albumsDir.create(recursive: true);
        }
        
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        coverPath = '${albumsDir.path}/cover_$fileName.jpg';
        await File(_albumCoverPath!).copy(coverPath);
      }

      final album = AlbumData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _albumTitleController.text,
        description: _albumDescController.text.isEmpty ? null : _albumDescController.text,
        coverImagePath: coverPath,
        media: [],
        isEnabled: true,
      );

      await _dataService.addAlbum(album);
      _showSuccess('Альбом создан');
      _clearAlbumForm();
      _loadAlbums();
      _tabController.animateTo(1);
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  void _clearAlbumForm() {
    _albumTitleController.clear();
    _albumDescController.clear();
    setState(() {
      _albumCoverPath = null;
    });
  }

  Future<void> _deleteAlbum(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить альбом?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Все фото и видео в альбоме будут удалены', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.deleteAlbum(id);
      _showSuccess('Альбом удалён');
      _loadAlbums();
    }
  }

  Future<void> _addMediaToAlbum(String albumId, bool isVideo) async {
    try {
      XFile? media;
      XFile? thumbnail;

      if (isVideo) {
        // Для видео сначала выбираем файл
        media = await _imagePicker.pickVideo(source: ImageSource.gallery);
        
        if (media != null) {
          // Затем предлагаем загрузить превью
          final loadThumbnail = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Загрузить превью?', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text('Хотите загрузить обложку для этого видео?', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Нет', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Да'),
                ),
              ],
            ),
          );
          
          if (loadThumbnail == true) {
            thumbnail = await _imagePicker.pickImage(source: ImageSource.gallery);
          }
        }
      } else {
        media = await _imagePicker.pickImage(source: ImageSource.gallery);
      }

      if (media != null) {
        // Copy files to albums directory
        final appDir = await getApplicationDocumentsDirectory();
        final albumsDir = Directory('${appDir.path}/albums');
        if (!await albumsDir.exists()) {
          await albumsDir.create(recursive: true);
        }

        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ext = isVideo ? 'mp4' : 'jpg';
        final newPath = '${albumsDir.path}/media_$fileName.$ext';
        await File(media.path).copy(newPath);

        String? thumbnailPath;
        if (thumbnail != null) {
          // Сохраняем превью
          final thumbPath = '${albumsDir.path}/thumb_$fileName.jpg';
          await File(thumbnail.path).copy(thumbPath);
          thumbnailPath = thumbPath;
        }

        final mediaData = MediaData(
          id: fileName,
          filePath: newPath,
          isVideo: isVideo,
          thumbnailPath: thumbnailPath, // Сохраняем путь к превью
          createdAt: DateTime.now(),
        );

        await _dataService.addMediaToAlbum(albumId, mediaData);
        _showSuccess(isVideo ? 'Видео добавлено' : 'Фото добавлено');
        _loadAlbums();
      }
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  Future<void> _removeMedia(String albumId, String mediaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить фото?', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.removeMediaFromAlbum(albumId, mediaId);
      _showSuccess('Фото удалено');
      _loadAlbums();
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _albumTitleController.dispose();
    _albumDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Создать альбом'),
            Tab(text: 'Альбомы'),
          ],
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Create album tab
              _buildCreateAlbumTab(),
              // Albums list tab
              _buildAlbumsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAlbumTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Новый альбом',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Cover image
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickAlbumCover,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: _albumCoverPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_albumCoverPath!), fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text('Обложка альбома', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          TextFormField(
            controller: _albumTitleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Название альбома',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          TextFormField(
            controller: _albumDescController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Описание (необязательно)',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          // Create button
          ElevatedButton(
            onPressed: _createAlbum,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Создать альбом',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_albums.isEmpty) {
      return const Center(
        child: Text('Нет альбомов', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: album.isEnabled ? AppColors.primary : Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with title and actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        album.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Показывать:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        Switch(
                          value: album.isEnabled,
                          onChanged: (value) async {
                            await _dataService.toggleAlbum(album.id);
                            _loadAlbums();
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Add media button
                    PopupMenuButton<String>(
                      onSelected: (value) => _addMediaToAlbum(album.id, value == 'video'),
                      icon: const Icon(Icons.add_circle, color: AppColors.accent, size: 28),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'photo', child: Text('Добавить фото')),
                        const PopupMenuItem(value: 'video', child: Text('Добавить видео')),
                      ],
                    ),
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.textPrimary),
                      onPressed: () => _editAlbum(album),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAlbum(album.id),
                    ),
                  ],
                ),
              ),
              // Media grid - scrollable horizontally
              SizedBox(
                height: 140,
                child: album.media.isEmpty
                    ? const Center(
                        child: Text(
                          'Нет медиафайлов\nДобавьте фото или видео',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: album.media.length,
                        itemBuilder: (context, i) {
                          final media = album.media[i];
                          // Пропускаем превью
                          if (media.id.endsWith('_thumb')) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: media.isVideo
                                      ? Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.deepPurple.shade800, Colors.blue.shade800],
                                            ),
                                          ),
                                          child: const Icon(Icons.videocam, color: Colors.white70, size: 40),
                                        )
                                      : (media.filePath.isNotEmpty && File(media.filePath).existsSync())
                                          ? Image.file(
                                              File(media.filePath),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : const Icon(Icons.image, color: AppColors.textSecondary),
                                ),
                                // Delete button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeMedia(album.id, media.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                if (media.isVideo)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ВИДЕО',
                                        style: TextStyle(color: Colors.white, fontSize: 8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              // Footer with count
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${album.media.where((m) => !m.id.endsWith('_thumb')).length} фото/видео',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editAlbum(AlbumData album) {
    _albumTitleController.text = album.title;
    _albumDescController.text = album.description ?? '';
    _albumCoverPath = album.coverImagePath;
    _tabController.animateTo(0);
  }
}
