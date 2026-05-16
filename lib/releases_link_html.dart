import 'dart:html' as html;

import 'package:flutter/material.dart';

const String _releasesPageUrl =
    'https://github.com/sharov68/my_pdf_helper/releases';

/// Открытие URL в браузере без url_launcher (на вебе плагин даёт MissingPluginException).
void _openInBrowser(String url) {
  if (url.startsWith('mailto:') || url.startsWith('tel:')) {
    final body = html.document.body;
    if (body == null) {
      html.window.location.href = url;
      return;
    }
    final anchor = html.AnchorElement(href: url)..style.display = 'none';
    body.append(anchor);
    anchor.click();
    anchor.remove();
    return;
  }
  html.window.open(url, '_blank');
}

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
    _openInBrowser(url);
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
