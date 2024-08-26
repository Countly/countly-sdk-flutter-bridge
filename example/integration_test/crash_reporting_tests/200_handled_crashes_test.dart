import 'dart:convert';
import 'dart:io';

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

    String crashLogs = 'crashErrorLogs';
    await Countly.addCrashLog(crashLogs);
    final segmentation = {'_facebook_version': '0.0.1'};
    final exceptionName = 'newException';
    await Countly.logException(exceptionName, true, segmentation);
    await Future.delayed(Duration(seconds: 1));
    await Countly.logException(exceptionName, false, segmentation);

    // divide by zero
    try {
      int firstInput = 20;
      int secondInput = 0;
      int result = firstInput ~/ secondInput;
      print('The result of [$firstInput] divided by [$secondInput] is [$result]');
    } catch (e, s) {
      await Countly.logExceptionEx(e as Exception, true, stacktrace: s);
      await Future.delayed(Duration(seconds: 1));
      await Countly.logExceptionEx(e, false, stacktrace: s);
    }

    // throw exception async
    final throwAsyncErrorString = 'throwExceptionAsync';
    try {
      await throwExceptionAsync(throwAsyncErrorString);
    } catch (e, s) {
      await Countly.recordDartError(e, s);
    }

    // throw state error
    final stateErrorString = 'stateError';
    try {
      throw StateError(stateErrorString);
    } catch (e, s) {
      await Countly.recordDartError(e, s);
    }

    // json crash
    final jsonDecodeErrorString = 'jsonDecodeError';
    try {
      Map<String, Object> options = json.decode(jsonDecodeErrorString);
      print(options.length);
    } catch (e, s) {
      await Countly.recordDartError(e, s);
    }

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    // Some logs for debugging
    printQueues(requestList, eventList);
    expect(requestList.length, 8);

    if (Platform.isAndroid) {
      crashLogs += '\n';
    }

    for (int i = 0; i < requestList.length; i++) {
      Map<String, List<String>> queryParams = Uri.parse('?' + requestList[i]).queryParametersAll;
      print(queryParams);
      print(i);
      testCommonRequestParams(queryParams);

      // The first request is begin_session. It will not have crash
      final Map<String, dynamic> crash = i == 0 ? {} : json.decode(queryParams['crash']![0]);

      if (i == 0) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 1) {
        expect((crash['_error'] as String).contains(exceptionName), true);
        expect(crash['_custom'], segmentation);
        expect(crash['_logs'], crashLogs);
        expect(crash['_nonfatal'], 'true');
      } else if (i == 2) {
        expect((crash['_error'] as String).contains(exceptionName), true);
        expect(crash['_custom'], segmentation);
        expect(crash['_logs'], crashLogs);
        expect(crash['_nonfatal'], 'false');
      } else if (i == 3) {
        expect((crash['_error'] as String).contains('IntegerDivisionByZeroException'), true);
        expect(crash['_logs'], crashLogs);
        expect(crash['_nonfatal'], 'true');
      } else if (i == 4) {
        expect((crash['_error'] as String).contains('IntegerDivisionByZeroException'), true);
        expect(crash['_logs'], crashLogs);
        expect(crash['_nonfatal'], 'false');
      } else if (i == 5) {
        expect((crash['_error'] as String).contains(throwAsyncErrorString), true);
        expect(crash['_logs'], crashLogs);
      } else if (i == 6) {
        expect((crash['_error'] as String).contains(stateErrorString), true);
        expect(crash['_logs'], crashLogs);
      } else if (i == 7) {
        expect((crash['_error'] as String).contains(jsonDecodeErrorString), true);
        expect(crash['_logs'], crashLogs);
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
