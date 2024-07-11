import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 8.Test the integrity of the old methods to ensure the work as before
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('8.Test the integrity of the old methods to ensure the work as before', (WidgetTester tester) async {
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

    await Countly.changeDeviceId('test', false);
    // Get the device ID type
    DeviceIdType? type1 = await Countly.getDeviceIDType();
    String? id1 = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type1, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id1, 'test');

    await Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
    // Get the device ID type
    DeviceIdType? type2 = await Countly.getDeviceIDType();
    String? id2 = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type2, DeviceIdType.TEMPORARY_ID);
    expect(id2, Countly.deviceIDType['TemporaryDeviceID']!);

    await Countly.changeDeviceId('', false);
    // Get the device ID type
    DeviceIdType? type3 = await Countly.getDeviceIDType();
    String? id3 = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type3, DeviceIdType.TEMPORARY_ID);
    expect(id3, Countly.deviceIDType['TemporaryDeviceID']!);
  });
}
