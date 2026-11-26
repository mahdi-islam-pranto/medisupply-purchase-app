import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_actions.dart';
import '../data/profile_models.dart';
import '../providers/profile_provider.dart';
import 'widgets/change_pin_sheet.dart';

/// Screen 8 — Profile: store info, Change PIN, notifications, Log out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(profileProvider);
    try {
      await ref.read(profileProvider.future);
    } catch (_) {
      // Shown by the listener / error view.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);
    final storeName = ref.watch(sessionProvider.select((s) => s.store?.name));

    ref.listen(profileProvider, (prev, next) {
      if (next.hasError && next.hasValue && !next.isLoading) {
        showAppSnackBar(context, errorMessage(next.error!), error: true);
      }
    });

    final header = ScreenHeader(title: 'Profile', subtitle: storeName);
    final logout = SecondaryButton(
      label: 'Log out',
      icon: Icons.logout_rounded,
      danger: true,
      onPressed: () => _confirmLogout(context, ref),
    );

    final Widget body;
    if (async.hasValue) {
      final data = async.requireValue;
      body = RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            header,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoCard(
                    data: data,
                    onChangePin: () => showChangePinSheet(context),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _NotificationList(items: data.notifications),
                  const SizedBox(height: 28),
                  logout,
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Log out stays reachable even when the profile can't load.
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: async.hasError
                ? ErrorView(
                    error: async.error!,
                    onRetry: () => ref.invalidate(profileProvider),
                  )
                : const SkeletonList(blocks: [196, 24, 72, 72, 72]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: logout),
        ],
      );
    }

    return SafeArea(bottom: false, child: body);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your App PIN to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) await logOut(ref);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data, required this.onChangePin});

  final ProfileData data;
  final VoidCallback onChangePin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final store = data.store;
    final phone = store?.phone;
    final email = store?.email;

    final rows = <Widget>[
      if (phone != null && phone.isNotEmpty)
        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
      if (email != null && email.isNotEmpty)
        _InfoRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: email,
        ),
      _InfoRow(
        icon: Icons.schedule_rounded,
        label: 'Quote window',
        value: '${data.window.range} daily',
      ),
      _InfoRow(
        icon: Icons.lock_outline_rounded,
        label: 'App PIN',
        value: '••••••',
        trailing: TextButton(
          onPressed: onChangePin,
          child: const Text('Change PIN'),
        ),
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store != null && store.name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: theme.titleMedium),
                        if (store.company != null && store.company!.isNotEmpty)
                          Text(
                            store.company!,
                            style: theme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 || store != null)
              const Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: theme.bodyLarge),
                ],
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items});
  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppCard(
        child: EmptyView(
          icon: Icons.notifications_none_rounded,
          title: 'No notifications',
          message:
              'Approvals, payments and quote windows from the last '
              '14 days show up here.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _NotificationTile(item: items[i]),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final AppNotification item;

  static (IconData, Color, Color) _style(NotificationType t) => switch (t) {
    NotificationType.quoteReviewed => (
      Icons.fact_check_outlined,
      AppColors.primaryLight,
      AppColors.primary,
    ),
    NotificationType.window => (
      Icons.schedule_rounded,
      AppColors.warningBg,
      AppColors.warningText,
    ),
    NotificationType.payment => (
      Icons.payments_outlined,
      AppColors.infoBg,
      AppColors.infoText,
    ),
    NotificationType.other => (
      Icons.notifications_none_rounded,
      AppColors.neutralBg,
      AppColors.textMuted,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final (icon, bg, fg) = _style(item.type);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(item.title, style: theme.titleSmall)),
                    if (item.timeAgo != null && item.timeAgo!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.timeAgo!,
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: theme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
