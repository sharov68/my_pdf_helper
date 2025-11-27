import 'package:flutter/material.dart';

Future<void> openReleasesLink(BuildContext context) async {
  // На нативных платформах ссылка в футере сейчас не используется.
  // Делаем безопасную заглушку.
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Ссылка на релизы доступна только в веб‑версии.'),
      duration: Duration(seconds: 4),
    ),
  );
}


