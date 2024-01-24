import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Goal of this test is to check apm configuration still works selectively (setting some and not setting other config options on native side)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Check selective apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // set some apm config options
    config.apm.enableForegroundBackgroundTracking().enableManualAppLoadedTrigger();
    await Countly.initWithConfig(config);

    // get test state
    Map<String, dynamic> state = await getTestState();

    // check if all apm config options are set correctly
    expect(state['isAppStartTimeTracked'], false);
    expect(state['isForegroundBackgroundEnabled'], true);
    expect(state['isManualAppLoadedTriggerEnabled'], true);
    expect(state['isStartTSOverridden'], false);
  });
}
