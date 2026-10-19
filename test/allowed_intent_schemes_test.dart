@TestOn('vm')
library allowed_intent_schemes_test;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async {
    await Countly.instance.halt();
  });

  test('Allowed intent schemes reach the platform in lower case, without the blocked and malformed ones', () async {
    final CountlyConfig config = CountlyConfig('https://example.com', 'app_key');
    config.content.setAllowedIntentSchemes(['HTTPS', ' myapp ', 'https', 'intent', 'data', 'zip', 'file', 'content', 'javascript', 'jar', 'https://', '']);
    config.push.setAllowedIntentSchemes(['market', 'Intent']);

    expect(config.content.allowedIntentSchemes, ['https', 'myapp']);
    expect(config.push.allowedIntentSchemes, ['market']);
    final Map<String, dynamic> sent = await initConfigSentFor(config);
    expect(sent['contentAllowedIntentSchemes'], ['https', 'myapp']);
    expect(sent['pushAllowedIntentSchemes'], ['market']);
  });

  test('A list without an allowed scheme keeps the default, and nothing is sent for it', () async {
    final CountlyConfig config = CountlyConfig('https://example.com', 'app_key');
    config.content.setAllowedIntentSchemes(['https']);
    config.content.setAllowedIntentSchemes(['intent', 'data', 'zip']);
    config.push.setAllowedIntentSchemes([]);

    expect(config.content.allowedIntentSchemes, isNull);
    expect(config.push.allowedIntentSchemes, isNull);
    final Map<String, dynamic> sent = await initConfigSentFor(config);
    expect(sent.containsKey('contentAllowedIntentSchemes'), isFalse);
    expect(sent.containsKey('pushAllowedIntentSchemes'), isFalse);
  });
}
