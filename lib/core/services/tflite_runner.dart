import 'tflite_runner_stub.dart';
import 'tflite_runner_stub.dart'
    if (dart.library.io) 'tflite_runner_io.dart' as runner_impl;

export 'tflite_runner_stub.dart';

Future<TFLiteModelRunner?> createTFLiteRunner(String assetPath) {
  return runner_impl.loadTFLiteModel(assetPath);
}
