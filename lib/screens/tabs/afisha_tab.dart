import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';
import '../../services/data_service.dart';

class AfishaTab extends StatefulWidget {
  const AfishaTab({super.key});

  @override
  State<AfishaTab> createState() => _AfishaTabState();
}

class _AfishaTabState extends State<AfishaTab> {
  final _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate; // Nullable - date is optional
  String? _imagePath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _selectedDate = null; // Start with no date
  }

  Future<void> _loadEvents() async {
    await _dataService.loadEvents();
    if (mounted) setState(() {});
  }

  String? _editingEventId;

  Future<void> _pickImage() async {
    print('_pickImage called');
    try {
      print('Calling picker.pickImage...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      print('Picker result: $image');
      if (image != null) {
        print('Image selected: ${image.path}');
        setState(() {
          _imagePath = image.path;
        });
      } else {
        print('No image selected (user cancelled)');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showError('Ошибка при выборе изображения: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    print('Save button pressed');
    
    if (_imagePath == null) {
      print('No image selected');
      _showError('Выберите изображение для афиши');
      return;
    }

    print('Image path: $_imagePath');

    try {
      String newPath = _imagePath!;
      
      // If this is a new event (not editing), copy image
      if (_editingEventId == null) {
        final appDir = await getApplicationDocumentsDirectory();
        final eventsDir = Directory('${appDir.path}/events');
        if (!await eventsDir.exists()) {
          await eventsDir.create(recursive: true);
        }
        
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        newPath = '${eventsDir.path}/$fileName.jpg';
        print('Copying image from $_imagePath to $newPath');
        await File(_imagePath!).copy(newPath);
        print('Image copied successfully');
      }

      // Create or update event - date is optional now
      final event = EventData(
        id: _editingEventId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.isEmpty ? 'Без названия' : _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        imagePath: newPath,
        date: _selectedDate ?? DateTime(2020, 1, 1), // Default to 2020 if not set
        location: _locationController.text.isEmpty ? 'Место не указано' : _locationController.text,
        isEnabled: true,
      );

      print('Saving event: ${event.title}');
      
      if (_editingEventId != null) {
        // Update existing event
        await _dataService.deleteEvent(_editingEventId!);
      }
      await _dataService.addEvent(event);
      
      print('Event saved successfully');
      
      _showSuccess(_editingEventId != null ? 'Афиша обновлена' : 'Афиша добавлена');
      _cancelEdit();
      _loadEvents();
    } catch (e) {
      print('Error saving event: $e');
      _showError('Ошибка сохранения: $e');
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить афишу?', style: TextStyle(color: AppColors.textPrimary)),
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
      await _dataService.deleteEvent(id);
      _showSuccess('Афиша удалена');
      _loadEvents();
    }
  }

  Future<void> _editEvent(EventData event) async {
    // Set current values
    _titleController.text = event.title == 'Без названия' ? '' : event.title;
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location == 'Место не указано' ? '' : event.location;
    // Set date to null if it's the default (2020)
    _selectedDate = event.date.year == 2020 && event.date.month == 1 && event.date.day == 1 ? null : event.date;
    _imagePath = event.imagePath;
    _editingEventId = event.id;

    // Scroll to top
    print('Editing event: ${event.id}');
  }

  void _cancelEdit() {
    _clearForm();
    setState(() {
      _editingEventId = null;
    });
  }

  Future<void> _toggleEvent(String id, bool currentStatus) async {
    await _dataService.toggleEvent(id);
    _loadEvents();
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    setState(() {
      _imagePath = null;
      _selectedDate = DateTime.now();
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Form for adding new event
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Добавить афишу',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      print('Image picker tapped');
                      _pickImage();
                    },
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
                              child: Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textSecondary),
                                SizedBox(height: 8),
                                Text(
                                  'Нажмите для выбора изображения',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
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
                      labelText: 'Название мероприятия (необязательно)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Описание (необязательно)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Date
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate != null
                                ? DateFormat('dd MMMM yyyy', 'ru_RU').format(_selectedDate!)
                                : 'Дата не указана (необязательно)',
                            style: TextStyle(
                              color: _selectedDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              if (_selectedDate != null)
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const Icon(Icons.calendar_today, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Место проведения (необязательно)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Save and Cancel buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _editingEventId != null ? 'Сохранить' : 'Добавить афишу',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_editingEventId != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Отмена',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
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
        // List of added events
        const Divider(color: AppColors.primary, thickness: 2),
        Expanded(
          flex: 3,
          child: FutureBuilder<List<EventData>>(
            future: _dataService.loadEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Нет добавленных афиш',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                );
              }

              final events = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: event.isEnabled ? AppColors.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image preview
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: 16/9,
                            child: event.imagePath.isNotEmpty
                                ? Image.file(
                                    File(event.imagePath),
                                    fit: BoxFit.cover,
                                  )
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
                                event.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMMM yyyy', 'ru_RU').format(event.date),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.location,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Toggle switch
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text('Показывать:', style: TextStyle(color: AppColors.textSecondary)),
                                        Switch(
                                          value: event.isEnabled,
                                          onChanged: (value) => _toggleEvent(event.id, event.isEnabled),
                                          activeColor: AppColors.primary,
                                        ),
                                        Text(
                                          event.isEnabled ? 'Да' : 'Нет',
                                          style: TextStyle(
                                            color: event.isEnabled ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Edit button
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.accent),
                                    onPressed: () => _editEvent(event),
                                    tooltip: 'Редактировать',
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteEvent(event.id),
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
