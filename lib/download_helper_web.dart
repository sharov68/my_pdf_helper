import 'dart:html' as html;
import 'dart:typed_data';

/// Реализация для web: создаём Blob и инициируем скачивание через скрытую ссылку.
Future<void> downloadBytes(String fileName, List<int> bytes) async {
  final data = Uint8List.fromList(bytes);
  final blob = html.Blob([data], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}


