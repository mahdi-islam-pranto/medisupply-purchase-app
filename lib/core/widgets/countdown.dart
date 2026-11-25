import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds every second with the time left until [deadline].
/// Calls [onDone] once when it reaches zero, so the screen can reload
/// (e.g. the quote window just opened or closed).
class Countdown extends StatefulWidget {
  const Countdown({
    super.key,
    required this.deadline,
    required this.builder,
    this.onDone,
  });

  final DateTime deadline;
  final Widget Function(BuildContext context, int secondsLeft) builder;
  final VoidCallback? onDone;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;
  late int _left;
  bool _fired = false;

  int _secondsLeft() {
    final ms = widget.deadline.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    if (old.deadline != widget.deadline) {
      _timer?.cancel();
      _start();
    }
  }

  void _start() {
    _left = _secondsLeft();
    // Only fire onDone on a real "running → zero" change. If the data
    // already says 0, firing again would reload in a loop.
    _fired = _left == 0;
    if (_left > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final left = _secondsLeft();
    if (left != _left) setState(() => _left = left);
    if (left == 0) {
      _timer?.cancel();
      if (!_fired) {
        _fired = true;
        widget.onDone?.call();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _left);
}
