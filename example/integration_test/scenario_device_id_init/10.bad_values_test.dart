import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 10.Test bad values
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('10.Test bad values', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('');
    await Countly.initWithConfig(config);

    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.SDK_GENERATED);
    expect(id!.length, Platform.isIOS ? 36 : 16);
    expect(id, isNot('test'));

    await Countly.instance.deviceId.setID('test');
    await Countly.instance.deviceId.setID('');

    // Get the device ID type
    DeviceIdType? type1 = await Countly.instance.deviceId.getIDType();
    String? id1 = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type1, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id1, 'test');
  });
}
