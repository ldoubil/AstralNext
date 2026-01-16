// lib/ui/pages/logs_page.dart
import 'package:flutter/material.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '日志输出',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
