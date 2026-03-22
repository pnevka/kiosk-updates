import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/settings_service.dart';
import '../../services/update_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _settingsService = SettingsService();
  final _updateService = UpdateService();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hasPassword = false;
  bool _slideshowEnabled = false;
  int _slideshowInterval = 30;
  int _idleTimeout = 60;
  bool _isCheckingUpdate = false;
  String? _currentVersion;
  String? _latestVersion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    _currentVersion = await _updateService.getCurrentVersion();
    if (mounted) setState(() {});
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    final updateInfo = await _updateService.checkForUpdates();

    setState(() {
      _isCheckingUpdate = false;
    });

    if (updateInfo != null) {
      _latestVersion = updateInfo['version'];
      _showUpdateDialog(updateInfo);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Установлена последняя версия'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Доступно обновление', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Текущая версия: $_currentVersion', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Новая версия: ${updateInfo['version']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(updateInfo['description'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadUpdate(updateInfo['downloadUrl']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Скачать'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate(String downloadUrl) async {
    // Скачиваем и устанавливаем обновление
    final success = await _updateService.downloadAndInstall(downloadUrl, (progress) {
      // Обновляем прогресс (можно добавить UI)
      print('Progress: ${progress * 100}%');
    });
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке обновления'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _hasPassword = settings.adminPassword != null;
      _slideshowEnabled = settings.slideshowEnabled;
      _slideshowInterval = settings.slideshowInterval;
      _idleTimeout = settings.idleTimeout;
    });
  }

  Future<void> _setPassword() async {
    if (_passwordController.text.isEmpty) {
      _showError('Введите пароль');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }
    if (_passwordController.text.length < 4) {
      _showError('Пароль должен быть не менее 4 символов');
      return;
    }

    await _settingsService.setPassword(_passwordController.text);
    _showSuccess('Пароль установлен');
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _hasPassword = true;
    });
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty) {
      _showError('Введите новый пароль');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }

    await _settingsService.setPassword(_passwordController.text);
    _showSuccess('Пароль изменён');
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _removePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить пароль?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Админ-панель будет доступна без пароля', style: TextStyle(color: AppColors.textSecondary)),
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
      await _settingsService.setPassword(null);
      _showSuccess('Пароль удалён');
      setState(() {
        _hasPassword = false;
      });
    }
  }

  Future<void> _toggleSlideshow(bool value) async {
    await _settingsService.setSlideshowEnabled(value);
    setState(() {
      _slideshowEnabled = value;
    });
    _showSuccess(value ? 'Слайд-шоу включено' : 'Слайд-шоу выключено');
  }

  Future<void> _setSlideshowInterval(int value) async {
    await _settingsService.setSlideshowInterval(value);
    setState(() {
      _slideshowInterval = value;
    });
    _showSuccess('Интервал установлен: $value сек');
  }

  Future<void> _setIdleTimeout(int value) async {
    await _settingsService.setIdleTimeout(value);
    setState(() {
      _idleTimeout = value;
    });
    _showSuccess('Простой установлен: $value сек');
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App version & update check
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Версия приложения',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentVersion ?? 'Загрузка...',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                  icon: _isCheckingUpdate
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.system_update),
                  label: Text(_isCheckingUpdate ? 'Проверка...' : 'Обновить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Password settings
          const Text(
            'Пароль админ-панели',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_hasPassword) ...[
                  const Text(
                    'Пароль не установлен',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Придумайте пароль',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Подтвердите пароль',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _setPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Установить пароль',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Пароль установлен',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Подтвердите новый пароль',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Изменить',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _removePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Удалить',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Slideshow settings
          const Text(
            'Слайд-шоу',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Включить слайд-шоу',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    Switch(
                      value: _slideshowEnabled,
                      onChanged: _toggleSlideshow,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                const Divider(color: AppColors.primary, height: 24),
                // Slideshow interval
                const Text(
                  'Интервал показа слайдов (секунды)',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _slideshowInterval.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$_slideshowInterval сек',
                        activeColor: AppColors.primary,
                        onChanged: _slideshowEnabled
                            ? (value) => _setSlideshowInterval(value.toInt())
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_slideshowInterval',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Idle timeout
                const Text(
                  'Время простоя до включения (секунды)',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _idleTimeout.toDouble(),
                        min: 10,
                        max: 600,
                        divisions: 59,
                        label: '$_idleTimeout сек',
                        activeColor: AppColors.primary,
                        onChanged: _slideshowEnabled
                            ? (value) => _setIdleTimeout(value.toInt())
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_idleTimeout',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Слайд-шоу включится через $_idleTimeout сек бездействия. Тап по экрану выключит его.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
