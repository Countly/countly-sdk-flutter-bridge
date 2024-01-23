import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Goal of this test is to check if all new apm configuration default options are working (not setting a config option on native side)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Check no apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // set no apm config options
    await Countly.initWithConfig(config);

    // check if apm config options are not set
    bool appStart = await channelTest.invokeMethod('isAppStartTimeTracked');
    bool fBEnabled = await channelTest.invokeMethod('isFBEnabled');
    bool manualTrigger = await channelTest.invokeMethod('isManualAppLoadedTriggerEnabled');
    bool tSOverride = await channelTest.invokeMethod('isStartTSOverridden');
    expect(appStart, false);
    expect(fBEnabled, false);
    expect(manualTrigger, false);
    expect(tSOverride, false);
  });
}
