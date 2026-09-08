// Stub implementation for non-web platforms
Future<void> playWordWeb(String word) async {
  throw UnsupportedError('Web TTS is only available on web platform');
}

List<Map<String, String>> getBrowserVoices() {
  return [];
}
