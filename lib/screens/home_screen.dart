import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../widgets/afisha_carousel.dart';
import '../widgets/menu_button.dart';
import '../widgets/logo_header.dart';
import 'admin_panel.dart';
import 'slideshow_screen.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StreamController<DateTime> _timeController;
  late Timer _timer;
  final _settingsService = SettingsService();

  // Admin panel activation
  int _topLeftTaps = 0;
  int _bottomRightTaps = 0;
  bool _awaitingBottomRight = false;
  Timer? _tapResetTimer;

  // Refresh carousel when returning from admin
  int _refreshCounter = 0;

  // Idle detection for slideshow
  Timer? _idleTimer;
  Timer? _settingsCheckTimer;
  bool _slideshowActive = false;

  @override
  void initState() {
    super.initState();
    _timeController = StreamController<DateTime>.broadcast();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _timeController.add(DateTime.now());
    });

    // Проверяем настройки каждые 5 секунд
    _settingsCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _startIdleDetection();
    });

    _startIdleDetection();
  }

  Future<void> _startIdleDetection() async {
    final settings = await _settingsService.loadSettings();

    // Не перезапускаем если таймер уже работает с теми же настройками
    if (_idleTimer != null && _idleTimer!.isActive) {
      return;
    }

    print('Slideshow enabled: ${settings.slideshowEnabled}, idle timeout: ${settings.idleTimeout}s');

    if (settings.slideshowEnabled) {
      print('Starting idle timer for ${settings.idleTimeout} seconds');
      _idleTimer = Timer(Duration(seconds: settings.idleTimeout), () {
        if (mounted && !_slideshowActive) {
          print('Idle timeout - starting slideshow');
          _startSlideshow();
        }
      });
    }
  }

  void _resetIdleTimer() {
    if (_slideshowActive) {
      // Exit slideshow on tap
      Navigator.pop(context);
      _slideshowActive = false;
    }
    // Сбрасываем таймер - отменяем и создаём заново
    _idleTimer?.cancel();
    _startIdleDetection();
  }

  void _startSlideshow() {
    setState(() {
      _slideshowActive = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SlideshowScreen()),
    ).then((_) {
      setState(() {
        _slideshowActive = false;
      });
      _startIdleDetection();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _timeController.close();
    _tapResetTimer?.cancel();
    _idleTimer?.cancel();
    _settingsCheckTimer?.cancel();
    super.dispose();
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
  }

  void _handleTopLeftTap() {
    print('Top-left tap: ${_topLeftTaps + 1}');
    _topLeftTaps++;

    if (_topLeftTaps >= 3) {
      print('Top-left complete! Awaiting bottom-right');
      setState(() {
        _topLeftTaps = 0;
        _awaitingBottomRight = true;
        _bottomRightTaps = 0;
      });
      // Cancel any existing timer and start new one for bottom-right timeout
      _tapResetTimer?.cancel();
      _tapResetTimer = Timer(const Duration(seconds: 5), () {
        print('Timeout - resetting');
        setState(() {
          _awaitingBottomRight = false;
          _bottomRightTaps = 0;
        });
      });
    } else {
      setState(() {});
      // Cancel previous timer and start new one
      _tapResetTimer?.cancel();
      _tapResetTimer = Timer(const Duration(seconds: 2), () {
        print('Resetting top-left taps');
        setState(() {
          _topLeftTaps = 0;
        });
      });
    }
  }

  void _handleBottomRightTap() {
    print('Bottom-right tap: $_bottomRightTaps, awaiting: $_awaitingBottomRight');
    if (!_awaitingBottomRight) {
      print('Not awaiting bottom-right');
      return;
    }

    _bottomRightTaps++;

    if (_bottomRightTaps >= 3) {
      print('Opening admin panel!');
      setState(() {
        _topLeftTaps = 0;
        _bottomRightTaps = 0;
        _awaitingBottomRight = false;
      });
      _tapResetTimer?.cancel();

      // Check password before opening admin panel
      _openAdminPanel();
    } else {
      setState(() {});
    }
  }

  Future<void> _openAdminPanel() async {
    final settings = await _settingsService.loadSettings();

    if (settings.adminPassword != null) {
      // Password is set, show dialog
      final passwordController = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Введите пароль', style: TextStyle(color: AppColors.textPrimary)),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Пароль',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) {
                  // Check password on Enter
                  if (settings.adminPassword == passwordController.text) {
                    Navigator.pop(context, true);
                  } else {
                    setDialogState(() {
                      passwordController.clear();
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    if (settings.adminPassword == passwordController.text) {
                      Navigator.pop(context, true);
                    } else {
                      setDialogState(() {
                        passwordController.clear();
                      });
                    }
                  },
                  child: const Text('Войти', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        ),
      );

      if (result != true) {
        print('Wrong password or cancelled');
        return;
      }
    }

    // Open admin panel
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPanel()),
    ).then((_) {
      // Refresh carousel and reload settings when returning from admin
      setState(() {
        _refreshCounter++;
      });
      // Сбрасываем таймер и запускаем заново с новыми настройками
      _idleTimer?.cancel();
      _startIdleDetection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetIdleTimer,
      onPanDown: (_) => _resetIdleTimer(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, AppColors.background],
                ),
              ),
            ),
            // Main content - на весь экран
            Column(
              children: [
                // Logo header at top
                const Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 15),
                  child: LogoHeader(),
                ),
                // Carousel - на всю доступную высоту
                Expanded(
                  flex: 2,
                  child: AfishaCarousel(key: ValueKey(_refreshCounter)),
                ),
                // Menu buttons - крупные, по центру, с отступами
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            child: MenuButton(
                              title: 'Афиша',
                              route: '/afisha',
                              icon: Icons.event_note,
                              onTap: () => _navigateTo('/afisha'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            child: MenuButton(
                              title: 'Кружки',
                              route: '/kruzhki',
                              icon: Icons.groups,
                              onTap: () => _navigateTo('/kruzhki'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            child: MenuButton(
                              title: 'Галерея',
                              route: '/gallery',
                              icon: Icons.photo_library,
                              onTap: () => _navigateTo('/gallery'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            child: MenuButton(
                              title: 'Контакты',
                              route: '/contacts',
                              icon: Icons.contacts,
                              onTap: () => _navigateTo('/contacts'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Clock - прижат к низу
                _buildClockFooter(),
              ],
            ),
            // Admin panel tap zones
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleTopLeftTap,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _awaitingBottomRight ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    border: _awaitingBottomRight ? Border.all(color: Colors.white.withOpacity(0.3), width: 2) : null,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _handleBottomRightTap,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _awaitingBottomRight ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    border: _awaitingBottomRight ? Border.all(color: Colors.white.withOpacity(0.3), width: 2) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockFooter() {
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      child: Center(
        child: StreamBuilder<DateTime>(
          stream: _timeController.stream,
          initialData: DateTime.now(),
          builder: (context, snapshot) {
            final now = snapshot.data!;
            return Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(now),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.4),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy', 'ru_RU').format(now),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
