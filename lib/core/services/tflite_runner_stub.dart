// Stub implementation for Flutter Web platform
// On Web, dart:ffi and native TFLite C libraries are unavailable.

abstract class TFLiteModelRunner {
  void run(Object input, Object output);
  void close();
}

Future<TFLiteModelRunner?> loadTFLiteModel(String assetPath) async {
  return null;
}
