import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Test crash reporting when using logException
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('200_CR_addCrashLog_test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableCrashReporting();
    await Countly.initWithConfig(config);

    final crashLogs = 'crash logs';
    await Countly.addCrashLog(crashLogs);
    final segmentation = {'_facebook_version': '0.0.1'};
    final exceptionName = 'newException';
    await Countly.logException(exceptionName, true, segmentation);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings

    // Some logs for debugging
    print('RQ: $requestList');
    print('RQ length: ${requestList.length}');
    expect(requestList.length, 2);

    for (int i = 0; i < requestList.length; i++) {
      Map<String, List<String>> queryParams = Uri.parse('?' + requestList[i]).queryParametersAll;
      print(queryParams);
      print(i);
      testCommonRequestParams(queryParams);
      if (i == 0) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 1) {
        final Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        expect(crash['_custom'], segmentation);
        expect(crash['_logs'], crashLogs + '\n');
        expect((crash['_error'] as String).contains(exceptionName), true);
      }
      print('RQ.$i: $queryParams');
      print('========================');
    }
  });
}
