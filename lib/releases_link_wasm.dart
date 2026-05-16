import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const String _releasesPageUrl =
    'https://github.com/sharov68/my_pdf_helper/releases';

/// Flutter Web (Wasm): нет `dart:html` и нет `dart.library.html` — только
/// `dart.library.js_interop`. Открываем ссылки через `package:web`, без
/// `url_launcher` (иначе MissingPluginException).
void _openInBrowser(String url) {
  if (url.startsWith('mailto:') || url.startsWith('tel:')) {
    final body = web.document.body;
    if (body == null) {
      web.window.location.href = url;
      return;
    }
    final anchor = web.HTMLAnchorElement()..href = url;
    anchor.style.display = 'none';
    body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    return;
  }
  web.window.open(url, '_blank', 'noopener,noreferrer');
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
