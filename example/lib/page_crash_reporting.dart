import 'dart:async';
import 'dart:convert';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class CrashReportingPage extends StatelessWidget {
  void addCrashLog() {
    Countly.addCrashLog('User Performed Step A');
    Timer(const Duration(seconds: 5), () {
      Countly.logException('one.js \n two.js \n three.js', true, {'_facebook_version': '0.0.1'});
    });
  }

  void causeException() {
    Map<String, Object> options = json.decode('This is a on purpose error.');
    print(options.length);
  }

  void throwException() {
    throw StateError('This is an thrown Dart exception.');
  }

  void throwNativeException() {
    Countly.throwNativeException();
  }

  Future<void> throwExceptionAsync() async {
    Future<void> foo() async {
      throw StateError('This is an async Dart exception.');
    }

    Future<void> bar() async {
      await foo();
    }

    await bar();
  }

  void recordExceptionManually() {
    Countly.logException('This is a manually created exception', true, null);
  }

  void dividedByZero() {
    try {
      int firstInput = 20;
      int secondInput = 0;
      int result = firstInput ~/ secondInput;
      print('The result of $firstInput divided by $secondInput is $result');
    } catch (e, s) {
      Countly.logExceptionEx(e as Exception, true, stacktrace: s);
    }
  }

  void dividedByZeroNoCatch() {
    int firstInput = 20;
    int secondInput = 0;
    int result = firstInput ~/ secondInput;
    print('The result of $firstInput divided by $secondInput is $result');
  }

  @override
  Widget build(BuildContext context) {
    return CountlyPageScaffold(
      title: 'Crash Reporting',
      sections: [
        CountlySection(
          title: 'Report Crashes',
          children: [
            MyButton(text: 'Send Crash Report', type: CountlyButtonType.filled, onPressed: addCrashLog),
            MyButton(text: 'Record Exception Manually', type: CountlyButtonType.tonal, onPressed: recordExceptionManually),
          ],
        ),
        CountlySection(
          title: 'Trigger Exceptions',
          subtitle: 'These will crash the app or throw exceptions',
          children: [
            MyButton(text: 'Cause Exception', type: CountlyButtonType.outlined, onPressed: causeException),
            MyButton(text: 'Throw Exception', type: CountlyButtonType.outlined, onPressed: throwException),
            MyButton(text: 'Throw Exception Async', type: CountlyButtonType.outlined, onPressed: throwExceptionAsync),
            MyButton(text: 'Throw Native Exception', type: CountlyButtonType.outlined, onPressed: throwNativeException),
            MyButton(
              text: 'Async Error',
              type: CountlyButtonType.outlined,
              onPressed: () async {
                throw Error();
              },
            ),
          ],
        ),
        CountlySection(
          title: 'Division By Zero',
          children: [
            MyButton(text: 'Divided By Zero (Caught)', type: CountlyButtonType.tonal, onPressed: dividedByZero),
            MyButton(text: 'Divided By Zero (No Catch)', type: CountlyButtonType.outlined, onPressed: dividedByZeroNoCatch),
          ],
        ),
      ],
    );
  }
}
