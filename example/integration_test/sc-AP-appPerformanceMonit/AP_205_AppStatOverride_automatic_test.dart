import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if we can override the app start timestamp in automatic mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check no apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // get the ts of 1 hour ago in ms
    int ts = DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch;
    config.apm.setAppStartTimestampOverride(ts).enableAppStartTimeTracking();
    await Countly.initWithConfig(config);

    // wait for 5 seconds. Go to background and come back to foreground manually.
    // TODO(turtledreams): automate this
    print('Waiting for 5 seconds...');
    await tester.pump(Duration(seconds: 5));

    // check if there is 1 apm related requests in the queue
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, 1);
    Map<String, dynamic> apmRequest = await getApmParamsFromRequest(apmRequests[0]);
    print(apmRequest);
    expect(apmRequest['stz'], ts); // check if the timestamp is the same as the one we set
  });
}
