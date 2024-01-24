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

    // get test state
    Map<String, dynamic> state = await getTestState();

    // check if all apm config options are set correctly
    expect(state['isAppStartTimeTracked'], true);
    expect(state['isForegroundBackgroundEnabled'], false);
    expect(state['isManualAppLoadedTriggerEnabled'], false);
    expect(state['isStartTSOverridden'], false);
  });
}
