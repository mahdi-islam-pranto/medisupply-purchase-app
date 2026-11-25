import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width green button with a built-in loading spinner.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// Defaults to the theme height (54).
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: height == null
          ? null
          : FilledButton.styleFrom(minimumSize: Size.fromHeight(height!)),
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: loading,
        spinnerColor: AppColors.textMuted,
      ),
    );
  }
}

/// Outlined button. Set [danger] for "Log out".
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.negative : AppColors.primary;
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: AppColors.surface,
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: loading,
        spinnerColor: color,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    required this.spinnerColor,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final Color spinnerColor;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
