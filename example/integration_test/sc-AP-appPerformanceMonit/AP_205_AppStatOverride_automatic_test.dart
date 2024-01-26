import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if we can override the app start timestamp in automatic mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check automatic start time tracking override', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // get the ts of 1 hour ago in ms
    int ts = DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch;
    config.apm.setAppStartTimestampOverride(ts).enableAppStartTimeTracking();
    await Countly.initWithConfig(config);

    // wait for 2 seconds.
    print('Waiting for 2 seconds...');
    await tester.pump(Duration(seconds: 2));

    // check if there is 1 apm related requests in the queue
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, Platform.isIOS ? 0 : 1);
    if (Platform.isAndroid) {
      Map<String, dynamic> apmRequest = await getApmParamsFromRequest(apmRequests[0]);
      print(apmRequest);
      expect(apmRequest['stz'], ts); // check if the timestamp is the same as the one we set
    }
  });
}
