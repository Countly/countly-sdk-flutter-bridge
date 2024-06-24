import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 4.Check if setID() sets the device ID correctly
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('1.Test Device ID Type - Developer sets the ID using setID', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Countly.instance.deviceId.setID('test');

    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getDeviceIDType();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);

    // Get the device ID
    String? id = await Countly.instance.deviceId.getCurrentDeviceID();
    // Verify the device ID
    expect(id, 'test');
  });
}
