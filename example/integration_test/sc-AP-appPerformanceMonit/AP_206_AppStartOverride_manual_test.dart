import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if we can override the app start timestamp in manual mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check no apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // get the ts of 1 hour ago in ms
    int ts = DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch;
    config.apm.setAppStartTimestampOverride(ts).enableAppStartTimeTracking().enableManualAppLoadedTrigger();
    await Countly.initWithConfig(config);

    print('Waiting for 2 seconds...');
    await tester.pump(Duration(seconds: 2));

    // trigger app loaded
    await Countly.appLoadingFinished();

    // check if there is 1 apm related requests in the queue
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, 1);
    Map<String, dynamic> apmRequest = await getApmParamsFromRequest(apmRequests[0]);
    print(apmRequest);
    expect(apmRequest['stz'], ts); // check if the timestamp is the same as the one we set
  });
}
