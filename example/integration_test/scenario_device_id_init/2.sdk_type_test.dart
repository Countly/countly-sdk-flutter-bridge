import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 2.Check if the SDK generates a device ID and the type is SDK_GENERATED
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('2.Test Device ID Type - SDK generates ID', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.getDeviceIDType();
    String? id = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type, DeviceIdType.SDK_GENERATED);
    expect(id!.length, Platform.isIOS ? 36 : 16);
    expect(id, isNot('test'));
  });

  testWidgets('2.Test Device ID Type - SDK generates ID using Device ID Module', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getDeviceIDType();
    String? id = await Countly.instance.deviceId.getCurrentDeviceID();
    // Verify the device ID type
    expect(type, DeviceIdType.SDK_GENERATED);
    expect(id!.length, Platform.isIOS ? 36 : 16);
    expect(id, isNot('test'));
  });
}
