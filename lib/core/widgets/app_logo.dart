import 'package:flutter/material.dart';

/// MediSupply BD logo.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 160});

  final double size;

  static const String asset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'MediSupply BD',
    );
  }
}
