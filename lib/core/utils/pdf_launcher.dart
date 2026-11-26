import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/snackbars.dart';

/// Opens a PDF link in the phone's browser / PDF viewer, which
/// shows or downloads it. Shows a message if nothing can open it.
Future<void> openPdf(BuildContext context, Uri uri) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    showAppSnackBar(
      context,
      'Could not open the PDF. Please install a browser or PDF viewer.',
      error: true,
    );
  }
}
