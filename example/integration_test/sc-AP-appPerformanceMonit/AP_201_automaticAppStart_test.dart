import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// This test checks if app load time is tracked correctly with enableAppStartTimeTracking but without manual trigger
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check automatic app load time', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.enableAppStartTimeTracking();
    await Countly.initWithConfig(config);

    // wait for 2 seconds.
    print('Waiting for 2 seconds...');
    await tester.pump(Duration(seconds: 2));

    // one request should be sent
    List<String> apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, Platform.isAndroid ? 1 : 0);

    if (Platform.isAndroid) {
      // get apm params
      Map<String, dynamic> apmParams = await getApmParamsFromRequest(apmReqs[0]);
      // get duration and check time (expecting 2 seconds but currently we got ~5)
      int duration = apmParams['apm_metrics']['duration'];
      print(duration);
      expect(duration > 0, true);
      expect(duration < 3000, true); // ms
    }

    // manually call appLoadingFinished and wait for 2 seconds
    await Countly.appLoadingFinished();
    await tester.pump(Duration(seconds: 2));

    // no extra apm requests should be sent
    apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, Platform.isAndroid ? 1 : 0);
  });
}
