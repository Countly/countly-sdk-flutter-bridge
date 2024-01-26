import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if all options (except app start override) are working correctly together
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check apm configuration working together, except ts override', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.enableAppStartTimeTracking().enableManualAppLoadedTrigger().enableForegroundBackgroundTracking();
    await Countly.initWithConfig(config);

    // trigger app loaded
    await Countly.appLoadingFinished();

    // wait for 5 seconds. go to background manually
    print('Waiting for 5 seconds...');
    await tester.pump(Duration(seconds: 5));

    // check if there is 3 apm related requests in the queue
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, 3);
    Map<String, dynamic> apmRequest_1 = await getApmParamsFromRequest(apmRequests[0]);
    Map<String, dynamic> apmRequest_2 = await getApmParamsFromRequest(apmRequests[1]);
    Map<String, dynamic> apmRequest_3 = await getApmParamsFromRequest(apmRequests[2]);
    expect(apmRequest_1['name'], 'app_start');
    expect(apmRequest_2['name'], 'app_in_foreground');
    expect(apmRequest_3['name'], 'app_in_background');
  });
}
