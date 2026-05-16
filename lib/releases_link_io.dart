import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String _releasesPageUrl =
    'https://github.com/sharov68/my_pdf_helper/releases';

Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Некорректная ссылка.'),
        duration: Duration(seconds: 4),
      ),
    );
    return;
  }

  try {
    final isMailOrTel = uri.scheme == 'mailto' || uri.scheme == 'tel';
    final mode = isMailOrTel
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;
    final launched = await launchUrl(uri, mode: mode);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть ссылку.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка при открытии ссылки: $e'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Future<void> openReleasesLink(BuildContext context) {
  return openExternalUrl(context, _releasesPageUrl);
}
