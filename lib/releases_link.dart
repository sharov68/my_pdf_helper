import 'package:flutter/material.dart';

// Порядок важен: dart2js/ddc — сначала `dart.library.html`;
// Wasm Web — `dart.library.html` нет, зато есть `dart.library.js_interop`;
// VM (Linux/Windows/…) — оба false → `releases_link_io.dart` + url_launcher.
import 'releases_link_io.dart'
    if (dart.library.html) 'releases_link_html.dart'
    if (dart.library.js_interop) 'releases_link_wasm.dart'
    as impl;

Future<void> openExternalUrl(BuildContext context, String url) {
  return impl.openExternalUrl(context, url);
}

Future<void> openReleasesLink(BuildContext context) {
  return impl.openReleasesLink(context);
}
