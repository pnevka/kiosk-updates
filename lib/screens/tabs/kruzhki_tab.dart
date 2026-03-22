import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';
import '../../services/data_service.dart';
import '../../models/admin_content.dart';

class KruzhkiTab extends StatefulWidget {
  const KruzhkiTab({super.key});

  @override
  State<KruzhkiTab> createState() => _KruzhkiTabState();
}

class _KruzhkiTabState extends State<KruzhkiTab> {
  final _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _ageController = TextEditingController();
  final _instructorController = TextEditingController();
  final _whatYouLearnController = TextEditingController();
  String? _imagePath;
  String? _qrImagePath;
  String? _editingId;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    await _dataService.loadCircles();
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      _showError('Ошибка при выборе изображения: $e');
    }
  }

  Future<void> _pickQrImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() {
          _qrImagePath = image.path;
        });
      }
    } catch (e) {
      _showError('Ошибка при выборе QR-кода: $e');
    }
  }

  Future<void> _saveCircle() async {
    if (_imagePath == null) {
      _showError('Выберите изображение');
      return;
    }

    try {
      String newPath = _imagePath!;
      String? newQrPath = _qrImagePath;
      
      if (_editingId == null) {
        final appDir = await getApplicationDocumentsDirectory();
        final circlesDir = Directory('${appDir.path}/circles');
        if (!await circlesDir.exists()) {
          await circlesDir.create(recursive: true);
        }
        
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        newPath = '${circlesDir.path}/$fileName.jpg';
        await File(_imagePath!).copy(newPath);
        
        // Copy QR code if selected
        if (_qrImagePath != null) {
          final qrFileName = '${fileName}_qr.jpg';
          newQrPath = '${circlesDir.path}/$qrFileName';
          await File(_qrImagePath!).copy(newQrPath!);
        }
      }

      final circle = CircleData(
        id: _editingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.isEmpty ? 'Без названия' : _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        schedule: _scheduleController.text.isEmpty ? null : _scheduleController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        price: _priceController.text.isEmpty ? null : _priceController.text,
        age: _ageController.text.isEmpty ? null : _ageController.text,
        imagePath: newPath,
        qrImagePath: newQrPath,
        instructor: _instructorController.text.isEmpty ? null : _instructorController.text,
        whatYouLearn: _whatYouLearnController.text.isEmpty ? null : _whatYouLearnController.text,
        isEnabled: true,
      );

      if (_editingId != null) {
        await _dataService.deleteCircle(_editingId!);
      }
      await _dataService.addCircle(circle);
      
      _showSuccess(_editingId != null ? 'Кружок обновлён' : 'Кружок добавлен');
      _cancelEdit();
      _loadCircles();
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    }
  }

  Future<void> _deleteCircle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить кружок?', style: TextStyle(color: AppColors.textPrimary)),
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
      await _dataService.deleteCircle(id);
      _showSuccess('Кружок удалён');
      _loadCircles();
    }
  }

  void _editCircle(CircleData circle) {
    _titleController.text = circle.title == 'Без названия' ? '' : circle.title;
    _descriptionController.text = circle.description ?? '';
    _scheduleController.text = circle.schedule ?? '';
    _locationController.text = circle.location ?? '';
    _priceController.text = circle.price ?? '';
    _ageController.text = circle.age ?? '';
    _instructorController.text = circle.instructor ?? '';
    _whatYouLearnController.text = circle.whatYouLearn ?? '';
    _imagePath = circle.imagePath;
    _qrImagePath = circle.qrImagePath;
    _editingId = circle.id;
  }

  void _cancelEdit() {
    _titleController.clear();
    _descriptionController.clear();
    _scheduleController.clear();
    _locationController.clear();
    _priceController.clear();
    _ageController.clear();
    _instructorController.clear();
    _whatYouLearnController.clear();
    setState(() {
      _imagePath = null;
      _qrImagePath = null;
      _editingId = null;
    });
  }

  Future<void> _toggleCircle(String id) async {
    await _dataService.toggleCircle(id);
    _loadCircles();
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
    _titleController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Form
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _editingId != null ? 'Редактировать кружок' : 'Добавить кружок',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: _imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textSecondary),
                                SizedBox(height: 8),
                                Text('Нажмите для выбора фото', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Название (необязательно)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Описание',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  // Instructor
                  TextFormField(
                    controller: _instructorController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Руководитель',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // What you'll learn
                  TextFormField(
                    controller: _whatYouLearnController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Чему вы научитесь',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // QR Code
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickQrImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent, width: 2, style: BorderStyle.solid),
                      ),
                      child: _qrImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_qrImagePath!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2, size: 48, color: AppColors.accent),
                                SizedBox(height: 8),
                                Text('QR-код (необязательно)', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Schedule
                  TextFormField(
                    controller: _scheduleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Расписание (например: Пн-Ср-Пт 18:00)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Место',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Price and Age
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Цена (необязательно)',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Возраст (необязательно)',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCircle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _editingId != null ? 'Сохранить' : 'Добавить',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_editingId != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Отмена', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // List
        const Divider(color: AppColors.primary, thickness: 2),
        Expanded(
          flex: 3,
          child: FutureBuilder<List<CircleData>>(
            future: _dataService.loadCircles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Нет кружков', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                );
              }

              final circles = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: circles.length,
                itemBuilder: (context, index) {
                  final circle = circles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: circle.isEnabled ? AppColors.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: 16/9,
                            child: circle.imagePath.isNotEmpty && File(circle.imagePath).existsSync()
                                ? Image.file(File(circle.imagePath), fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.background,
                                    child: const Icon(Icons.image, size: 48, color: AppColors.textSecondary),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                circle.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (circle.schedule != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  circle.schedule!,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text('Показывать:', style: TextStyle(color: AppColors.textSecondary)),
                                        Switch(
                                          value: circle.isEnabled,
                                          onChanged: (value) => _toggleCircle(circle.id),
                                          activeColor: AppColors.primary,
                                        ),
                                        Text(
                                          circle.isEnabled ? 'Да' : 'Нет',
                                          style: TextStyle(
                                            color: circle.isEnabled ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.accent),
                                    onPressed: () => _editCircle(circle),
                                    tooltip: 'Редактировать',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCircle(circle.id),
                                    tooltip: 'Удалить',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
