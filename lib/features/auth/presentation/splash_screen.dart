import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shown for a moment at start-up while the saved sign-in is read.
/// Same icon, size and white background as the native launch screen
/// (flutter_native_splash), so the hand-over is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/images/lon_icon.jpg'),
              width: 192,
              height: 192,
              semanticLabel: 'Medi Purchase',
            ),
            SizedBox(height: 24),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
