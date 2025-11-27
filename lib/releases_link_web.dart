import 'dart:html' as html;

import 'package:flutter/material.dart';

Future<void> openReleasesLink(BuildContext context) async {
  try {
    html.window.open(
      'https://github.com/sharov68/my_pdf_helper/releases',
      '_blank',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка при открытии страницы релизов: $e'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}


