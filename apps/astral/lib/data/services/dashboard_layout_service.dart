import 'dart:convert';
import 'dart:io';

import 'package:astral/ui/pages/dashboard/models/dashboard_layout.dart';
import 'package:path_provider/path_provider.dart';

class DashboardLayoutService {
  static const _fileName = 'dashboard_layout.json';

  Future<String> get _filePath async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<DashboardLayout> load() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (!await file.exists()) {
        return DashboardLayout.defaultLayout;
      }
      final content = await file.readAsString();
      return DashboardLayout.fromJson(content);
    } catch (e) {
      return DashboardLayout.defaultLayout;
    }
  }

  Future<void> save(DashboardLayout layout) async {
    try {
      final path = await _filePath;
      final file = File(path);
      await file.writeAsString(layout.toJson());
    } catch (e) {
      // ignore
    }
  }

  Future<void> reset() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // ignore
    }
  }
}
