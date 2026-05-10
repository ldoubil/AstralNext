import 'package:flutter/material.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

class ShellContentController extends ChangeNotifier {
  WidgetBuilder? _overlayContentBuilder;
  String? _overlayTitle;
  VoidCallback? _onClose;

  WidgetBuilder? get overlayContentBuilder => _overlayContentBuilder;
  String? get overlayTitle => _overlayTitle;
  bool get hasOverlay => _overlayContentBuilder != null;

  void showOverlay({
    required WidgetBuilder contentBuilder,
    required String title,
    VoidCallback? onClose,
  }) {
    _overlayContentBuilder = contentBuilder;
    _overlayTitle = title;
    _onClose = onClose;
    notifyListeners();
  }

  void closeOverlay() {
    _onClose?.call();
    _overlayContentBuilder = null;
    _overlayTitle = null;
    _onClose = null;
    notifyListeners();
  }
}
