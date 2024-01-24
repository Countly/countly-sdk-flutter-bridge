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

    // get test state
    Map<String, dynamic> state = await getTestState();

    // check if all apm config options are set correctly
    expect(state['isAppStartTimeTracked'], false);
    expect(state['isForegroundBackgroundEnabled'], false);
    expect(state['isManualAppLoadedTriggerEnabled'], false);
    expect(state['isStartTSOverridden'], false);
  });
}
