import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/core/utils/gallery_saver.dart';

void main() {
  testWidgets('captures the whole sheet, including off-screen rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800); // small screen
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 50, child: Text('Line $i')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final png = await tester.runAsync(() => captureToPng(key));
    expect(png, isNotNull);
    final codec = await tester.runAsync(() => ui.instantiateImageCodec(png!));
    final frame = await tester.runAsync(() => codec!.getNextFrame());
    final img = frame!.image;
    // 40 rows × 50 px = 2000 px tall (screen is only 800) × ratio 2.0.
    expect(img.height, 4000);
    expect(img.width, 800);
  });
}
