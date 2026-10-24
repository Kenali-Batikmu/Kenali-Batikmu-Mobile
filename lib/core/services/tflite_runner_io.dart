// IO implementation for native platforms (Android, iOS, Windows, macOS, Linux)
// Utilizes tflite_flutter with native C-bindings

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'tflite_runner_stub.dart';

class IOTFLiteModelRunner implements TFLiteModelRunner {
  final Interpreter _interpreter;

  IOTFLiteModelRunner(this._interpreter);

  @override
  void run(Object input, Object output) {
    _interpreter.run(input, output);
  }

  @override
  void close() {
    _interpreter.close();
  }
}

Future<TFLiteModelRunner?> loadTFLiteModel(String assetPath) async {
  try {
    final options = InterpreterOptions()..threads = 4;
    final interpreter = await Interpreter.fromAsset(assetPath, options: options);
    interpreter.allocateTensors();
    debugPrint('TFLite IO: Model $assetPath berhasil dialokasikan via native interpreter');
    return IOTFLiteModelRunner(interpreter);
  } catch (e) {
    debugPrint('TFLite IO interpreter fallback: $e');
    return null;
  }
}
