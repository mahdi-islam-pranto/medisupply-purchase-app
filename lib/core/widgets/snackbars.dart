import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Short message at the bottom of the screen.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? const Color(0xFFFF8A80) : AppColors.primaryLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.primaryLight,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
