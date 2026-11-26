import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';

/// Album the app saves into (Gallery on Android, Photos on iPhone).
const String galleryAlbum = 'Medi Purchase';

/// Problem while making or saving the image, with a user-facing message.
class GallerySaveException implements Exception {
  const GallerySaveException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Renders the [RepaintBoundary] behind [key] to a PNG.
///
/// The boundary must be fully laid out (e.g. inside a
/// SingleChildScrollView, not a lazy ListView) so the whole content is
/// captured, including parts scrolled off screen.
Future<Uint8List> captureToPng(
  GlobalKey key, {
  double maxPixelHeight = 12000,
}) async {
  final ctx = key.currentContext;
  final boundary = ctx?.findRenderObject();
  if (ctx == null || boundary is! RenderRepaintBoundary) {
    throw const GallerySaveException('Nothing to save yet.');
  }
  // Called from a button tap, so the sheet is already painted.
  final dpr = MediaQuery.devicePixelRatioOf(ctx);

  final height = boundary.size.height;
  // Sharp on any phone, but keep very long orders to a sane file size.
  final ratio = math.min(
    dpr.clamp(2.0, 3.0),
    height > 0 ? maxPixelHeight / height : 3.0,
  );

  final ui.Image image = await boundary.toImage(pixelRatio: ratio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const GallerySaveException('Could not create the image.');
    }
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Saves PNG bytes into the [galleryAlbum] album. Asks for permission
/// if needed (only older Android / iPhone ask).
Future<void> saveToGallery(Uint8List png, {required String name}) async {
  try {
    await Gal.putImageBytes(png, album: galleryAlbum, name: name);
  } on GalException catch (e) {
    throw GallerySaveException(switch (e.type) {
      GalExceptionType.permissionDenied =>
        'Allow access to Photos/Gallery in Settings to save images.',
      GalExceptionType.notEnoughSpace => 'Not enough space on the phone.',
      _ => 'Could not save the image. Please try again.',
    });
  }
}

/// Opens the phone's gallery app.
Future<void> openGallery() => Gal.open();
