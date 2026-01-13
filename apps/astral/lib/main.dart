import 'package:flutter/material.dart';

import 'di.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDI(); // 注册 GetIt 依赖
  runApp(const AstralApp());
}
