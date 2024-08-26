import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 1.Test Visibility Tracking - Test that the SDK works properly when visibility is not enabled
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('1.Test Visibility Tracking - Test that the SDK works properly when visibility is not enabled', (WidgetTester tester) async {
    await tester.pumpWidget(CountlyVisibilityDectector(child: testApp()));

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await Countly.recordEvent({'key': 'value'});
    await testLastEventParams({'key': 'value', '__v__': isNull});

    await goToBackground(tester);
    await Countly.recordEvent({'key': 'value1'});
    await testLastEventParams({'key': 'value1', '__v__': isNull});
  });
}
