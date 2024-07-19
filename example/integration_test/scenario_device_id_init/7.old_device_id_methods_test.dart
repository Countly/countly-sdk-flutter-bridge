import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 7. Init with no device ID in config
/// change device ID with merge
/// change device ID without merge
/// enter temporary ID mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('7.Old device ID methods test', (WidgetTester tester) async {
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
    await testLastRequestParams({'device_id': id});

    String oldID = id;

    await Countly.changeDeviceId('test', true);

    // Get the device ID type
    type = await Countly.getDeviceIDType();
    id = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');
    await testLastRequestParams({'old_device_id': oldID, 'device_id': 'test'});

    await Countly.changeDeviceId('', false);
    await Countly.changeDeviceId('test2', false);
    await Countly.changeDeviceId('', false);

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    // Get the device ID type
    type = await Countly.getDeviceIDType();
    id = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test2');
    await testLastRequestParams({'device_id': 'test2'});

    await Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    // Get the device ID type
    type = await Countly.getDeviceIDType();
    id = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type, DeviceIdType.TEMPORARY_ID);
    expect(id, Countly.deviceIDType['TemporaryDeviceID']!);
    await testLastRequestParams({'device_id': Countly.deviceIDType['TemporaryDeviceID']!});
  });
}
