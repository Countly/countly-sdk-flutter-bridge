import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 5.Test Visibility Tracking - Test that the SDK handles visibility properly when initialized in foreground and event is recorded in the foreground
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('5.Test Visibility Tracking - Test that the SDK handles visibility properly when initialized in foreground and event is recorded in the foreground', (WidgetTester tester) async {
    await tester.pumpWidget(CountlyVisibilityDectector(child: testApp()));
    await tester.pump(Duration(seconds: 3));
    await goToForeground(tester);
    await tester.pump(Duration(seconds: 3));

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableVisibilityTracking();
    await Countly.initWithConfig(config);

    await Countly.recordEvent({'key': 'value'});
    await testLastEventParams({'key': 'value', '__v__': 1});

    await goToBackground(tester);
    await Countly.recordEvent({'key': 'value1'});
    await testLastEventParams({'key': 'value1', '__v__': 0});
  });
}
