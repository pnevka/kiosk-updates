import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/constants.dart';
import 'tabs/afisha_tab.dart';
import 'tabs/kruzhki_tab.dart';
import 'tabs/gallery_tab.dart';
import 'tabs/settings_tab.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _currentIndex = 0;
  final _settingsService = SettingsService();
  final _dataService = DataService();

  final List<Widget> _tabs = [
    const AfishaTab(),
    const KruzhkiTab(),
    const GalleryTab(),
    const SettingsTab(),
  ];

  final List<String> _tabTitles = [
    'Афиша',
    'Кружки',
    'Галерея',
    'Настройки',
  ];

  final List<IconData> _tabIcons = [
    Icons.event_note,
    Icons.groups,
    Icons.photo_library,
    Icons.settings,
  ];

  Future<void> _refreshData() async {
    await _dataService.loadEvents();
    await _dataService.loadCircles();
    await _dataService.loadAlbums();
    await _settingsService.loadSettings();
    
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные обновлены'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _closeApp() async {
    // Показываем диалог подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Закрыть приложение?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      exit(0); // Принудительно закрываем приложение
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Админ-панель',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                      onPressed: _refreshData,
                      tooltip: 'Обновить данные',
                    ),
                    const SizedBox(width: 8),
                    // Close app button
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: _closeApp,
                      tooltip: 'Закрыть приложение',
                    ),
                    const SizedBox(width: 8),
                    // Logout button
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Выйти',
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                color: AppColors.surface,
                child: Row(
                  children: List.generate(_tabTitles.length, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? AppColors.primary
                                : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _tabIcons[index],
                                color: AppColors.textPrimary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tabTitles[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Content
              Expanded(child: _tabs[_currentIndex]),
            ],
          ),
        ),
      ),
    );
  }
}
