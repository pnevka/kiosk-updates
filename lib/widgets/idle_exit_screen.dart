import 'dart:async';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Миксин для экранов с таймаутом возврата на главную
mixin IdleExitMixin<T extends StatefulWidget> on State<T> {
  Timer? _idleTimer;
  final _settingsService = SettingsService();
  int _idleExitTimeout = 180;

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  Future<void> _startIdleTimer() async {
    final settings = await _settingsService.loadSettings();
    _idleExitTimeout = settings.idleExitTimeout;

    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(seconds: _idleExitTimeout), () {
      if (mounted) {
        print('[IdleExitMixin] Таймаут бездействия — возврат на главную');
        exitToHome(context);
      }
    });
  }

  void resetIdleTimer() {
    _startIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  /// Возврат на главный экран
  void exitToHome(BuildContext context);
}
