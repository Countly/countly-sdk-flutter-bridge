import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Initializes the SDK with [config] and returns the config the Dart side hands to the platform.
Future<Map<String, dynamic>> initConfigSentFor(CountlyConfig config) async {
  Map<String, dynamic>? sent;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('countly_flutter'), (MethodCall call) async {
    if (call.method == 'init') {
      final List<dynamic> args = jsonDecode((call.arguments as Map<Object?, Object?>)['data'] as String) as List<dynamic>;
      sent = args[0] as Map<String, dynamic>;
    }
    return null;
  });
  await Countly.initWithConfig(config);
  return sent!;
}
