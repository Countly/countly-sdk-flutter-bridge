import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// A session update delay below one second is ignored, so the default delay applies and the SDK
/// does not queue session updates continuously.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A session update delay below 1 second is ignored', (WidgetTester tester) async {
    final CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true);
    config.setUpdateSessionTimerDelay(0);
    expect(config.sessionUpdateTimerDelay, isNull);
    config.setUpdateSessionTimerDelay(-5);
    expect(config.sessionUpdateTimerDelay, isNull);

    await Countly.initWithConfig(config);
    final int queuedBefore = (await getRequestQueue()).where((request) => request.contains('session_duration=')).length;
    await Future<void>.delayed(const Duration(seconds: 5));

    final int queuedAfter = (await getRequestQueue()).where((request) => request.contains('session_duration=')).length;
    expect(queuedAfter - queuedBefore, 0);
  });
}
