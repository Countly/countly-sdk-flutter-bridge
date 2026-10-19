import 'dart:ui';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// Crash reporting records Flutter and asynchronous errors and still passes each one on to the
/// handlers the app set before init, such as another crash reporting tool.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Crash reporting records errors and passes them on to the handlers set before it', (WidgetTester tester) async {
    final FlutterExceptionHandler? bindingFlutterHandler = FlutterError.onError;
    final ErrorCallback? bindingPlatformHandler = PlatformDispatcher.instance.onError;
    final List<String> appFlutterErrors = [];
    final List<String> appPlatformErrors = [];
    FlutterError.onError = (FlutterErrorDetails details) => appFlutterErrors.add(details.exceptionAsString());
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      appPlatformErrors.add(error.toString());
      return true;
    };

    try {
      await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY)
        ..setLoggingEnabled(true)
        ..enableCrashReporting());
      // Unique per run because the request queue survives between runs on a device.
      final String run = DateTime.now().millisecondsSinceEpoch.toString();

      FlutterError.reportError(FlutterErrorDetails(exception: StateError('flutter_error_$run')));
      final bool handled = PlatformDispatcher.instance.onError!(StateError('async_error_$run'), StackTrace.current);
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(appFlutterErrors.where((error) => error.contains('flutter_error_$run')), hasLength(1));
      expect(appPlatformErrors.where((error) => error.contains('async_error_$run')), hasLength(1));
      expect(handled, isTrue);

      final List<String> requests = await getRequestQueue();
      expect(requests.where((request) => request.contains('crash=') && request.contains('flutter_error_$run')), hasLength(1));
      expect(requests.where((request) => request.contains('crash=') && request.contains('async_error_$run')), hasLength(1));
    } finally {
      FlutterError.onError = bindingFlutterHandler;
      PlatformDispatcher.instance.onError = bindingPlatformHandler;
    }
  });
}
