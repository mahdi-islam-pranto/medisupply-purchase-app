import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/connectivity.dart';
import '../core/theme/app_colors.dart';
import '../features/home/providers/home_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/quote/providers/quote_providers.dart';
import '../features/reports/providers/reports_providers.dart';

/// Scaffold with the bottom navigation: Home · Quote · History · Reports · Profile.
/// Also shows an offline banner and refreshes live data (the quote window
/// may have opened or closed) when the app returns to the foreground.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Shorter trips away (e.g. a quick look at the calculator) keep the data.
  static const _staleAfter = Duration(seconds: 30);

  late final AppLifecycleListener _lifecycle;
  DateTime? _hiddenAt;

  StatefulNavigationShell get shell => widget.shell;

  static const _tabs = [
    _TabItem('Home', Icons.home_outlined, Icons.home_rounded),
    _TabItem('Quote', Icons.edit_note_outlined, Icons.edit_note_rounded),
    _TabItem('History', Icons.history_outlined, Icons.history_rounded),
    _TabItem('Reports', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _TabItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt ??= DateTime.now(),
      onShow: () {
        final hiddenAt = _hiddenAt;
        _hiddenAt = null;
        if (hiddenAt != null &&
            DateTime.now().difference(hiddenAt) >= _staleAfter) {
          _refreshLiveData();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Reloads screens whose numbers depend on the time of day. Screens keep
  /// showing the old data while the new data loads; typed quote prices are
  /// kept separately and survive. History is left alone so its scroll
  /// position and loaded pages are not lost.
  void _refreshLiveData() {
    ref.invalidate(homeProvider);
    ref.invalidate(quoteProvider);
    ref.invalidate(reportProvider);
    ref.invalidate(profileProvider);
  }

  void _onTap(int index) {
    // Tapping the current tab again goes back to its first screen.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineProvider).value ?? true;

    // Back online: fetch fresh data (failed screens recover on their own).
    ref.listen(onlineProvider, (prev, next) {
      if (prev?.value == false && next.value == true) _refreshLiveData();
    });

    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OfflineBanner(visible: !online),
          _BottomNav(
            items: _tabs,
            currentIndex: shell.currentIndex,
            onTap: _onTap,
          ),
        ],
      ),
    );
  }
}

/// Slim dark strip above the bottom navigation while the phone is offline.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: AppColors.text,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are offline. Showing the last loaded data.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    labelStyle: labelStyle,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.labelStyle,
    required this.onTap,
  });

  final _TabItem item;
  final bool selected;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Green bar on top of the active tab, as in the design.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(3),
                ),
              ),
            ),
            const Spacer(),
            Icon(selected ? item.activeIcon : item.icon, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: labelStyle?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
