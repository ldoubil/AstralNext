// lib/ui/pages/dashboard_page.dart
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(50)),
      child: Container(
        color: colorScheme.surfaceVariant,
        child: const Center(
          child: Text('面板内容', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
