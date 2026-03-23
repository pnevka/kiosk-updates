import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';
import '../../services/data_service.dart';
import '../../services/video_thumbnail_service.dart';
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

      if (isVideo) {
        media = await _imagePicker.pickVideo(source: ImageSource.gallery);
      } else {
        media = await _imagePicker.pickImage(source: ImageSource.gallery);
      }

      if (media != null) {
        // Copy file to albums directory
        final appDir = await getApplicationDocumentsDirectory();
        final albumsDir = Directory('${appDir.path}/albums');
        if (!await albumsDir.exists()) {
          await albumsDir.create(recursive: true);
        }

        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ext = isVideo ? 'mp4' : 'jpg';
        final newPath = '${albumsDir.path}/media_$fileName.$ext';
        await File(media.path).copy(newPath);

        final mediaData = MediaData(
          id: fileName,
          filePath: newPath,
          isVideo: isVideo,
          createdAt: DateTime.now(),
        );

        // Генерируем превью для видео
        if (isVideo) {
          print('[GalleryTab] Генерация превью для видео: $newPath');
          final thumbnailPath = await VideoThumbnailService().generateThumbnail(newPath);
          if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
            print('[GalleryTab] Превью создано: $thumbnailPath');
            final thumbData = MediaData(
              id: '${mediaData.id}_thumb',
              filePath: thumbnailPath,
              isVideo: false,
              createdAt: DateTime.now(),
            );
            await _dataService.addMediaToAlbum(albumId, thumbData);
          }
        }

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
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16/9,
                  child: album.coverImagePath != null && File(album.coverImagePath!).existsSync()
                      ? Image.file(File(album.coverImagePath!), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.background,
                          child: const Icon(Icons.photo_library, size: 48, color: AppColors.textSecondary),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (album.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        album.description!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${album.media.length} фото/видео',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Toggle
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Показывать:', style: TextStyle(color: AppColors.textSecondary)),
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
                        ),
                        // Add media button
                        PopupMenuButton<String>(
                          onSelected: (value) => _addMediaToAlbum(album.id, value == 'video'),
                          icon: const Icon(Icons.add_circle, color: AppColors.accent),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'photo', child: Text('Добавить фото')),
                            const PopupMenuItem(value: 'video', child: Text('Добавить видео')),
                          ],
                        ),
                        // Delete album
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAlbum(album.id),
                          tooltip: 'Удалить альбом',
                        ),
                      ],
                    ),
                    // Media list
                    if (album.media.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: album.media.length,
                          itemBuilder: (context, i) {
                            final media = album.media[i];
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary, width: 1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: media.isVideo
                                        ? Container(
                                            color: Colors.black54,
                                            child: const Icon(Icons.videocam, color: Colors.white),
                                          )
                                        : Image.file(File(media.filePath), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeMedia(album.id, media.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
