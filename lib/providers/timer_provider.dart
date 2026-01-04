import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  String? _selectedSubject;

  int get seconds => _seconds;
  int get minutes => _seconds ~/ 60;
  bool get isRunning => _isRunning;
  String? get selectedSubject => _selectedSubject;

  String get formattedTime {
    final hours = _seconds ~/ 3600;
    final mins = (_seconds % 3600) ~/ 60;
    final secs = _seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _seconds = 0;
    _isRunning = false;
    _selectedSubject = null;
    notifyListeners();
  }

  void setSubject(String subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  int stopAndGetMinutes() {
    _timer?.cancel();
    _isRunning = false;
    final mins = (_seconds / 60).ceil();
    notifyListeners();
    return mins > 0 ? mins : 1; // En az 1 dakika
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
