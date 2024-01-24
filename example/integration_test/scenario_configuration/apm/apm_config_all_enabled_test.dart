import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Goal of this test is to check if all new apm configuration options are working (setting a config option on native side)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Check all apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // set apm config options
    config.apm.enableForegroundBackgroundTracking().enableAppStartTimeTracking().enableManualAppLoadedTrigger().setAppStartTimestampOverride(123456789);
    await Countly.initWithConfig(config);

    // get test state
    Map<String, dynamic> state = await getTestState();

    // check if all apm config options are set
    expect(state['isAppStartTimeTracked'], true);
    expect(state['isForegroundBackgroundEnabled'], true);
    expect(state['isManualAppLoadedTriggerEnabled'], true);
    expect(state['isStartTSOverridden'], true);
  });
}
