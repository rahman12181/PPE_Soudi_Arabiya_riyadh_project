import 'package:flutter/material.dart';

class SlideProvider extends ChangeNotifier {
  bool _showSlideToPunch = false;
  bool _isPunchInMode = true;
  Function(bool)? _punchCallback;
  double _slideProgress = 0.0;
  
  bool get showSlideToPunch => _showSlideToPunch;
  bool get isPunchInMode => _isPunchInMode;
  double get slideProgress => _slideProgress;
  
  void showSlideButton(bool isPunchIn, Function(bool) punchCallback) {
    _showSlideToPunch = true;
    _isPunchInMode = isPunchIn;
    _punchCallback = punchCallback;
    _slideProgress = 0.0;
    notifyListeners();
  }
  
  void hideSlideButton() {
    _showSlideToPunch = false;
    _punchCallback = null;
    _slideProgress = 0.0;
    notifyListeners();
  }
  
  void updateSlideProgress(double progress) {
    _slideProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  void completePunch() {
    if (_punchCallback != null) {
      _punchCallback!(_isPunchInMode);
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      hideSlideButton();
    });
  }
}