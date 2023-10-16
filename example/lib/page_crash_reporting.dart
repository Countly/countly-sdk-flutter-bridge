import 'dart:async';
import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
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
      print('Exception occurs: $e');
      print('STACK TRACE\n: $s');
      Countly.logExceptionEx(e as Exception, true, stacktrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crash Reporting'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Send Crash Report', color: 'violet', onPressed: addCrashLog),
            MyButton(text: 'Cause Exception', color: 'orange', onPressed: causeException),
            MyButton(text: 'Throw Exception', color: 'orange', onPressed: throwException),
            MyButton(text: 'Throw Exception Async', color: 'orange', onPressed: throwExceptionAsync),
            MyButton(text: 'Throw Native Exception', color: 'orange', onPressed: throwNativeException),
            MyButton(text: 'Record Exception Manually', color: 'teal', onPressed: recordExceptionManually),
            MyButton(text: 'Divided By Zero Exception', color: 'teal', onPressed: dividedByZero),
          ],
        )),
      ),
    );
  }
}
