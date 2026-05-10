part of 'package:astral/ui/pages/dashboard_page.dart';

class _InstanceMenuItem {
  final String path;
  final String name;
  final bool isRunning;

  const _InstanceMenuItem({
    required this.path,
    required this.name,
    required this.isRunning,
  });
}

class _PageHeader extends StatelessWidget {
  final String instanceName;
  final bool isInstanceRunning;
  final bool isEditingLayout;
  final List<_InstanceMenuItem> instances;
  final String? selectedPath;
  final ValueChanged<String>? onInstanceSelected;
  final VoidCallback? onEditLayout;

  const _PageHeader({
    required this.instanceName,
    required this.isInstanceRunning,
    required this.isEditingLayout,
    required this.instances,
    this.selectedPath,
    this.onInstanceSelected,
    this.onEditLayout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: MenuAnchor(
            style: MenuStyle(
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              )),
              elevation: WidgetStateProperty.all(3),
            ),
            builder: (context, controller, child) {
              return InkWell(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInstanceRunning
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        instanceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.unfold_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );
            },
            menuChildren: instances.map((item) {
              final isSelected = item.path == selectedPath;
              return MenuItemButton(
                leadingIcon: Icon(
                  Icons.circle,
                  size: 8,
                  color: item.isRunning
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
                trailingIcon: isSelected
                    ? Icon(Icons.check, size: 18, color: colorScheme.primary)
                    : null,
                onPressed: () => onInstanceSelected?.call(item.path),
                child: Text(item.name),
              );
            }).toList(),
          ),
        ),
        if (onEditLayout != null)
          isEditingLayout
              ? FilledButton.icon(
                  onPressed: onEditLayout,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('完成'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              : IconButton.outlined(
                  onPressed: onEditLayout,
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  tooltip: '编辑布局',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
      ],
    );
  }
}
