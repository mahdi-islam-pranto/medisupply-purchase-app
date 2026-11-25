import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White pill showing the window state: "Window open · closes 14:00".
class WindowChip extends StatelessWidget {
  const WindowChip({super.key, required this.label, required this.open});

  final String label;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.circle : Icons.lock_outline_rounded,
            size: open ? 9 : 14,
            color: open ? AppColors.positive : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.primaryDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
