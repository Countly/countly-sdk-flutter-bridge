@TestOn('vm')
library server_url_app_key_test;

import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final List<MethodCall> calls = <MethodCall>[];

  /// The names of the calls the platform received, in order.
  List<String> methods() => calls.map((MethodCall call) => call.method).toList();

  /// The arguments the Dart side sent with the call at [index], or null when it sent none.
  List<dynamic>? argumentsOf(int index) {
    final Object? arguments = calls[index].arguments;
    if (arguments is Map && arguments['data'] is String) {
      return jsonDecode(arguments['data'] as String) as List<dynamic>;
    }
    return null;
  }

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('countly_flutter'), (MethodCall call) async {
      calls.add(call);
      return call.method == 'init' ? 'initialized.' : null;
    });
  });

  tearDown(() async {
    await Countly.instance.halt();
  });

  test('Server URL, app key and queue calls reach the platform with the values as given, which the native SDK checks', () async {
    await Countly.initWithConfig(CountlyConfig('https://first.example.com', 'first_app_key'));

    await Countly.instance.changeServerUrl('https://second.example.com//');
    await Countly.instance.changeAppKey('second_app_key');
    await Countly.instance.changeServerUrl('not a url');
    await Countly.instance.changeAppKey('');
    await Countly.instance.flushQueues();

    expect(methods(), ['init', 'changeServerUrl', 'changeAppKey', 'changeServerUrl', 'changeAppKey', 'flushQueues']);
    expect(argumentsOf(1), ['https://second.example.com//']);
    expect(argumentsOf(2), ['second_app_key']);
    expect(argumentsOf(3), ['not a url']);
    expect(argumentsOf(4), ['']);
    expect(argumentsOf(5), isNull);
  });

  test('Before init and after halt, the calls are ignored and nothing reaches the platform', () async {
    await Countly.instance.changeServerUrl('https://second.example.com');
    await Countly.instance.changeAppKey('second_app_key');
    await Countly.instance.flushQueues();
    expect(calls, isEmpty);

    await Countly.initWithConfig(CountlyConfig('https://first.example.com', 'first_app_key'));
    await Countly.instance.halt();
    await Countly.instance.changeServerUrl('https://second.example.com');
    await Countly.instance.changeAppKey('second_app_key');
    await Countly.instance.flushQueues();

    expect(methods(), ['init', 'halt']);
  });
}
