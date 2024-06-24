import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 1.Check if setDeviceId() sets the device ID correctly and the type is DEVELOPER_SUPPLIED
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('1.Test Device ID Type - Developer sets the ID during init', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.getDeviceIDType();
    String? id = await Countly.getCurrentDeviceId();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');
  });

  testWidgets('1.Test Device ID Type - Developer sets the ID during init using Device ID Module', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getDeviceIDType();
    String? id = await Countly.instance.deviceId.getCurrentDeviceID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');
  });
}
