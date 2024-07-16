import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 1.Check if setDeviceId() sets the device ID correctly and the type is DEVELOPER_SUPPLIED
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('1.1.Test Device ID Type - BV - Developer sets the ID during init', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('');
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.getDeviceIDType();
    DeviceIdType? newModuleType = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.getCurrentDeviceId();
    String? newModuleId = await Countly.instance.deviceId.getID();

    expect(type, DeviceIdType.SDK_GENERATED);
    expect(newModuleType, DeviceIdType.SDK_GENERATED);
    expect(id!.length, Platform.isIOS ? 36 : 16);
    expect(newModuleId!.length, Platform.isIOS ? 36 : 16);
    expect(id, isNot(''));
    expect(newModuleId, isNot(''));
    expect(id, newModuleId);

    await testLastRequestParams({'device_id': id});
  });
}
