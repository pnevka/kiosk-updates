import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'app.dart';
import 'services/data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем media_kit для Windows — это позволит использовать кодеки из K-Lite
  VideoPlayerMediaKit.ensureInitialized(windows: true);

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    // Получаем размер первичного экрана
    final primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();
    final screenSize = primaryDisplay.size;

    const windowOptions = WindowOptions(
      size: Size(540, 960),
      minimumSize: Size(400, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true, // Скрываем из панели задач
      titleBarStyle: TitleBarStyle.hidden, // Скрываем заголовок
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Устанавливаем размер окна равным размеру экрана
      await windowManager.setSize(screenSize);
      await windowManager.setPosition(Offset.zero);
      // Полноэкранный режим без рамки
      await windowManager.setFullScreen(true);
      // Блокируем сворачивание и закрытие окна
      await windowManager.setPreventClose(true);
    });
  } else if (Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(540, 960),
      minimumSize: Size(400, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    });
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  print('Платформа: ${Platform.operatingSystem}');

  if (Platform.isWindows) {
    final primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();
    print('Размер экрана: ${primaryDisplay.size}');
  }

  runApp(const KioskApp());
}
