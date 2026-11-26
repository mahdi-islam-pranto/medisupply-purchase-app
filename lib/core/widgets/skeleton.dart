import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Gently pulsing grey blocks shown while a screen loads, shaped roughly
/// like the content that is coming.
class SkeletonList extends StatefulWidget {
  const SkeletonList({
    super.key,
    required this.blocks,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 16),
  });

  /// Heights of the blocks, top to bottom. A height below 30 is drawn as
  /// a short text line (e.g. a section title).
  final List<double> blocks;
  final EdgeInsetsGeometry padding;

  /// Home: hero card, "Today", three tiles, due card, last quote.
  static const home = [190.0, 20.0, 84.0, 76.0, 76.0];

  /// A list of cards (History, Quote).
  static const cards = [96.0, 96.0, 96.0, 96.0, 96.0, 96.0];

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No animation when the user asked the phone to reduce motion.
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) _pulse.stop();

    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: still
              ? const AlwaysStoppedAnimation(1)
              : Tween(begin: 0.45, end: 1.0).animate(_pulse),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: widget.padding,
            children: [
              for (final h in widget.blocks) ...[
                if (h < 30)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.35,
                    child: _Block(height: h, radius: 6),
                  )
                else
                  _Block(height: h, radius: AppTheme.radius),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height, required this.radius});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.neutralBg,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
