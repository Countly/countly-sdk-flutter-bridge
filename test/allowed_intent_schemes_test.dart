@TestOn('vm')
library allowed_intent_schemes_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'config_test_utils.dart';

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

  test('A list without an allowed scheme keeps the schemes set before, or the default when none were', () async {
    final CountlyConfig config = CountlyConfig('https://example.com', 'app_key');
    config.content.setAllowedIntentSchemes(['https']);
    config.content.setAllowedIntentSchemes(['intent', 'data', 'zip']);
    config.content.setAllowedIntentSchemes([]);
    config.push.setAllowedIntentSchemes(['javascript', 'not a scheme']);
    config.push.setAllowedIntentSchemes([]);

    expect(config.content.allowedIntentSchemes, ['https']);
    expect(config.push.allowedIntentSchemes, isNull);
    final Map<String, dynamic> sent = await initConfigSentFor(config);
    expect(sent['contentAllowedIntentSchemes'], ['https']);
    expect(sent.containsKey('pushAllowedIntentSchemes'), isFalse);
  });
}
