import 'package:flutter/material.dart';

class ShellContentController extends ChangeNotifier {
  Widget? _overlayContent;
  String? _overlayTitle;
  VoidCallback? _onClose;

  Widget? get overlayContent => _overlayContent;
  String? get overlayTitle => _overlayTitle;
  bool get hasOverlay => _overlayContent != null;

  void showOverlay({
    required Widget content,
    required String title,
    VoidCallback? onClose,
  }) {
    _overlayContent = content;
    _overlayTitle = title;
    _onClose = onClose;
    notifyListeners();
  }

  void closeOverlay() {
    _onClose?.call();
    _overlayContent = null;
    _overlayTitle = null;
    _onClose = null;
    notifyListeners();
  }
}
