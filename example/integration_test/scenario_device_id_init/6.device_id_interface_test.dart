import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 6. Init with no device ID in config
/// set ID (with merge)
/// set ID (without merge)
/// enter temporary ID mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('6.Device ID interface test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.getDeviceIDType();
    DeviceIdType? newModuleType = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.getCurrentDeviceId();
    String? newModuleId = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.SDK_GENERATED);
    expect(newModuleType, DeviceIdType.SDK_GENERATED);
    expect(id!.length, Platform.isIOS ? 36 : 16);
    expect(newModuleId!.length, Platform.isIOS ? 36 : 16);
    expect(id, isNot('test'));
    expect(newModuleId, isNot('test'));
    expect(id, newModuleId);
    await testLastRequestParams({'device_id': id});

    String oldID = id;

    await Countly.instance.deviceId.setID('test');
    // Get the device ID type
    type = await Countly.getDeviceIDType();
    newModuleType = await Countly.instance.deviceId.getIDType();
    id = await Countly.getCurrentDeviceId();
    newModuleId = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(newModuleType, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');
    expect(newModuleId, 'test');
    await testLastRequestParams({'old_device_id': oldID, 'device_id': 'test'});

    await Countly.instance.deviceId.setID('');
    await Countly.instance.deviceId.setID('test2');
    await Countly.instance.deviceId.setID('');

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    // Get the device ID type
    type = await Countly.getDeviceIDType();
    newModuleType = await Countly.instance.deviceId.getIDType();
    id = await Countly.getCurrentDeviceId();
    newModuleId = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(newModuleType, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test2');
    expect(newModuleId, 'test2');
    await testLastRequestParams({'device_id': 'test2'});

    await Countly.instance.deviceId.changeWithMerge('');
    await Countly.instance.deviceId.changeWithMerge('test');
    await Countly.instance.deviceId.changeWithMerge('');
    // Get the device ID type
    type = await Countly.getDeviceIDType();
    newModuleType = await Countly.instance.deviceId.getIDType();
    id = await Countly.getCurrentDeviceId();
    newModuleId = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(newModuleType, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');
    expect(newModuleId, 'test');
    await testLastRequestParams({'old_device_id': 'test2', 'device_id': 'test'});

    await Countly.instance.deviceId.changeWithoutMerge('');
    await Countly.instance.deviceId.changeWithoutMerge('test2');
    await Countly.instance.deviceId.changeWithoutMerge('');

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    // Get the device ID type
    type = await Countly.getDeviceIDType();
    newModuleType = await Countly.instance.deviceId.getIDType();
    id = await Countly.getCurrentDeviceId();
    newModuleId = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(newModuleType, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test2');
    expect(newModuleId, 'test2');
    await testLastRequestParams({'device_id': 'test2'});

    await Countly.instance.deviceId.enableTemporaryIDMode();

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    // Get the device ID type
    type = await Countly.getDeviceIDType();
    newModuleType = await Countly.instance.deviceId.getIDType();
    id = await Countly.getCurrentDeviceId();
    newModuleId = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.TEMPORARY_ID);
    expect(newModuleType, DeviceIdType.TEMPORARY_ID);
    expect(id, Countly.temporaryDeviceID);
    expect(newModuleId, Countly.temporaryDeviceID);
    await testLastRequestParams({'device_id': Countly.temporaryDeviceID});
  });
}
