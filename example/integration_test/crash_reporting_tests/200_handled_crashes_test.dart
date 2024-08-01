import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Test crash reporting with handling crashes
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('200_handled_crashes', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableCrashReporting();
    await Countly.initWithConfig(config);

    final crashLogs = 'crash logs';
    await Countly.addCrashLog(crashLogs);
    final segmentation = {'_facebook_version': '0.0.1'};
    final exceptionName = 'newException';
    await Countly.logException(exceptionName, true, segmentation);

    // divide by zero
    try {
      int firstInput = 20;
      int secondInput = 0;
      int result = firstInput ~/ secondInput;
      print('The result of [$firstInput] divided by [$secondInput] is [$result]');
    } catch (e, s) {
      Countly.logExceptionEx(e as Exception, true, stacktrace: s);
    }

    // throw exception async
    var errorString = 'jsonDecodeError';
    try {
      await throwExceptionAsync(errorString);
    } catch (e, s) {
      Countly.recordDartError(e, s);
    }

    // throw state error
    errorString = 'stateError';
    try {
      throw StateError(errorString);
    } catch (e, s) {
      Countly.recordDartError(e, s);
    }

    // json crash
    errorString = 'jsonDecodeError';
    try {
      Map<String, Object> options = json.decode(errorString);
      print(options.length);
    } catch (e, s) {
      Countly.recordDartError(e, s);
    }

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    // Some logs for debugging
    printQueues(requestList, eventList);
    // expect(requestList.length, 2);

    for (int i = 0; i < requestList.length; i++) {
      Map<String, List<String>> queryParams = Uri.parse('?' + requestList[i]).queryParametersAll;
      print(queryParams);
      print(i);
      testCommonRequestParams(queryParams);
      if (i == 0) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 1) {
        final Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        expect((crash['_error'] as String).contains('IntegerDivisionByZeroException'), true);
      }
      print('RQ.$i: $queryParams');
      print('========================');
    }
  });
}

Future<void> throwExceptionAsync(String errorString) async {
  Future<void> foo() async {
    throw StateError(errorString);
  }

  Future<void> bar() async {
    await foo();
  }

  await bar();
}
