import 'package:flutter/material.dart';

import 'releases_link_stub.dart'
    if (dart.library.html) 'releases_link_web.dart' as impl;

Future<void> openReleasesLink(BuildContext context) {
  return impl.openReleasesLink(context);
}


