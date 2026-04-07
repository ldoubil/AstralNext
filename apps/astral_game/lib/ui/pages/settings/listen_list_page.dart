import 'package:flutter/material.dart';
import 'settings_state.dart';

class ListenListPage extends StatelessWidget {
  const ListenListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final listenList = settingsState.listenList.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                '监听列表',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addListenItem(context),
                tooltip: '添加监听项',
              ),
            ],
          ),
        ),
        Expanded(
          child: listenList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt,
                          size: 64, color: colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('暂无监听项',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.outline,
                                  )),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _addListenItem(context),
                        icon: const Icon(Icons.add),
                        label: const Text('添加监听项'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: listenList.length,
                  itemBuilder: (context, index) {
                    final item = listenList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item),
                        leading: const Icon(Icons.dns),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: '编辑',
                              onPressed: () =>
                                  _editListenItem(context, index, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              tooltip: '删除',
                              onPressed: () =>
                                  _deleteListenItem(context, index, item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _addListenItem(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加监听项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '监听地址',
            hintText: 'tcp://0.0.0.0:8080',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final list = List<String>.from(settingsState.listenList.value);
      list.add(result.trim());
      settingsState.listenList.value = list;
    }
  }

  Future<void> _editListenItem(
    BuildContext context,
    int index,
    String item,
  ) async {
    final controller = TextEditingController(text: item);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑监听项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '监听地址',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result != item) {
      final list = List<String>.from(settingsState.listenList.value);
      list[index] = result.trim();
      settingsState.listenList.value = list;
    }
  }

  Future<void> _deleteListenItem(
    BuildContext context,
    int index,
    String item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除监听项 "$item" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final list = List<String>.from(settingsState.listenList.value);
      list.removeAt(index);
      settingsState.listenList.value = list;
    }
  }
}
