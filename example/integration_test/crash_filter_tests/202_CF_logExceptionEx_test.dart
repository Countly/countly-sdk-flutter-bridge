import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Test globalCrashFilterCallback when error is recorded from logExceptionEx
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('202_CF_logExceptionEx_test', (WidgetTester tester) async {
    final errorString = 'Division';
    final filterString = '*****';
    final segmentation = {'test_crash': 'test_segmentation'};
    final GlobalCrashFilterCallback globalCrashFilterCallback = (crashData) {
      print('GlobalCrashFilterCallback');

      // Check that the error string exists in the stackTrace
      expect(crashData.stackTrace.contains(errorString), true);
      expect(crashData.stackTrace.contains(filterString), false);

      final breadcrumbs = [...crashData.breadcrumbs];
      // update the breadcrumb.
      breadcrumbs.add('test');

      final crashMetrics = crashData.crashMetrics;
      // update the breadcrumb.
      crashMetrics.putIfAbsent('test_metric', () => 'test_crash');

      // return the updated crashdata.
      return crashData.copyWith(
        breadcrumbs: breadcrumbs,
        crashMetrics: crashMetrics,
        crashSegmentation: segmentation,
        fatal: true, // the fatal flag can be easily overridden
        stackTrace: crashData.stackTrace.replaceAll(errorString, filterString),
      );
    };

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setGlobalCrashFilterCallback(globalCrashFilterCallback).enableCrashReporting();
    await Countly.initWithConfig(config);

    try {
      int firstInput = 20;
      int secondInput = 0;
      int result = firstInput ~/ secondInput;
      print('The result of $firstInput divided by $secondInput is $result');
    } catch (e, s) {
      Countly.logExceptionEx(e as Exception, true, stacktrace: s);
    }
    await Future.delayed(Duration(seconds: 5));

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

        // Check if segmentation values are well recorded
        segmentation.forEach((k, v) => expect(crash['_custom'][k], v));
        // NB: crashMetrics and breadcrumbs can't be tested because flutter cannot send them to native SDKs
      }
      print('RQ.$i: $queryParams');
      print('========================');
    }
  });
}
