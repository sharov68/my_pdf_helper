/// Заглушка для не‑web платформ. На десктопе/мобилке мы работаем с файловой
/// системой напрямую, поэтому этот метод нигде не вызывается.
Future<void> downloadBytes(String fileName, List<int> bytes) async {
  // no-op
}


