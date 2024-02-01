import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// This tests goal is to check if app load time is tracked correctly with enableAppStartTimeTracking and enableManualAppLoadedTrigger
/// No requests should be sent without the manual trigger
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check manual app load time without trigger', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.enableAppStartTimeTracking().enableManualAppLoadedTrigger();
    await Countly.initWithConfig(config);

    // wait for 2 seconds.
    print('Waiting for 2 seconds...');
    await tester.pump(Duration(seconds: 2));

    // no request should be sent
    List<String> apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 0);
  });
}
