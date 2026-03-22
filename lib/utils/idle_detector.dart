import 'dart:async';
import 'package:flutter/material.dart';
import 'constants.dart';

class IdleDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onIdle;
  final Duration timeout;

  const IdleDetector({
    super.key,
    required this.child,
    required this.onIdle,
    this.timeout = AppDurations.idleTimeout,
  });

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, widget.onIdle);
  }

  void _onInteraction() {
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onInteraction(),
      child: GestureDetector(
        onTap: _onInteraction,
        onPanDown: (_) => _onInteraction(),
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      ),
    );
  }
}
