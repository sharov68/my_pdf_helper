import 'package:flutter/material.dart';

import 'releases_link_io.dart'
    if (dart.library.html) 'releases_link_html.dart' as impl;

Future<void> openExternalUrl(BuildContext context, String url) {
  return impl.openExternalUrl(context, url);
}

Future<void> openReleasesLink(BuildContext context) {
  return impl.openReleasesLink(context);
}
