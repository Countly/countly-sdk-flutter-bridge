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

    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'test'});
  });
}
