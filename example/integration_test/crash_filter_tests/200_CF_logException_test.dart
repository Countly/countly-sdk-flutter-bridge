import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Test globalCrashFilterCallback when error is recorded from logException
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('200_CF_logException_test', (WidgetTester tester) async {
    final errorString = 'SecretKey';
    final filterString = '*****';
    final GlobalCrashFilterCallback globalCrashFilterCallback = (crash) {
      // Check that the error string exists in the stackTrace
      expect(crash.stackTrace.contains(errorString), true);
      expect(crash.stackTrace.contains(filterString), false);

      return crash.copyWith(stackTrace: crash.stackTrace.replaceAll(errorString, filterString));
    };

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setGlobalCrashFilterCallback(globalCrashFilterCallback).enableCrashReporting();
    await Countly.initWithConfig(config);

    await Countly.logException(errorString, true);

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
        // Check that the error string has been replace in the Global callback
        expect((crash['_error'] as String).contains(errorString), false);
        expect((crash['_error'] as String).contains(filterString), true);
      }
      print('RQ.$i: $queryParams');
      print('========================');
    }
  });
}
