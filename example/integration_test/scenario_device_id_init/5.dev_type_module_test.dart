import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 5.Check if setDeviceId() sets the device ID correctly and the type is DEVELOPER_SUPPLIED using deviceID module
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('5.Test Device ID Type - Developer sets the ID during init using Device ID Module', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);
    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');
  });
}
