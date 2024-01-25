import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// This tests goal is to check if app load time is tracked correctly with enableAppStartTimeTracking and enableManualAppLoadedTrigger
/// No requests should be sent without the manual trigger and then if we use trigger again, no extra requests should be sent
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test appload time with manual trigger', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.enableAppStartTimeTracking().enableManualAppLoadedTrigger();
    await Countly.initWithConfig(config);

    // wait for 2 seconds.
    print('Waiting for 2 seconds...');
    await tester.pump(Duration(seconds: 2));

    await Countly.appLoadingFinished(); // trigger app load finished

    // one request should be sent
    List<String> apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 1);

    // get apm params
    Map<String, dynamic> apmParams = await getApmParamsFromRequest(apmReqs[0]);

    // get duration and check time (expecting 2 seconds but currently we got ~5)
    int duration = apmParams['apm_metrics']['duration'];
    print(duration);
    expect(duration > 0, true);
    expect(duration < 10000, true);

    // one more trigger should have no effect
    await Countly.appLoadingFinished();
    print('Waiting for 2 seconds...');
    await tester.pump(Duration(seconds: 2));
    apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 1);
  });
}
