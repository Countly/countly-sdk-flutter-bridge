import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Goal of this test is to check if the legacy configuration is still working (setting a config option on native side)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Check legacy apm configuration', (WidgetTester tester) async {
    // set apm config options (legacy)
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRecordAppStartTime(true);
    await Countly.initWithConfig(config);

    // check if apm config options are set correctly
    bool appStart = await channelTest.invokeMethod('isAppStartTimeTracked');
    expect(appStart, true);
  });
}
