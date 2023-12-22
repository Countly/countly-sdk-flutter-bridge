// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final String SERVER_URL = 'https://xxx.count.ly';
final String APP_KEY = 'YOUR_APP_KEY';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Test Device ID Type - SDK', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    DeviceIdType? type = await Countly.getDeviceIDType();
    expect(type, DeviceIdType.SDK_GENERATED);
  });
}
