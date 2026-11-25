import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/state_views.dart';

/// Temporary tab body used until each screen is built in its phase.
class PlaceholderTab extends ConsumerWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
    required this.phase,
    this.footer,
  });

  final String title;
  final IconData icon;
  final int phase;

  /// Optional widget pinned under the message (e.g. a Log out button).
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeName = ref.watch(sessionProvider.select((s) => s.store?.name));
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: title, subtitle: storeName),
          Expanded(
            child: EmptyView(
              icon: icon,
              title: '$title is on the way',
              message: 'This screen is built in Phase $phase.',
            ),
          ),
          if (footer != null)
            Padding(padding: const EdgeInsets.all(20), child: footer),
        ],
      ),
    );
  }
}
