import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  late StreamController<DateTime> _timeController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timeController = StreamController<DateTime>.broadcast();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _timeController.add(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _timeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQRCode(),
          StreamBuilder<DateTime>(
            stream: _timeController.stream,
            initialData: DateTime.now(),
            builder: (context, snapshot) {
              return _buildTime(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      width: AppSizes.qrSize,
      height: AppSizes.qrSize,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.qr_code_2, size: 50, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTime(DateTime now) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(DateFormat('HH:mm').format(now), style: AppTextStyles.time),
        Text(
          DateFormat('dd MMMM yyyy', 'ru_RU').format(now),
          style: AppTextStyles.screensaverHint.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}
