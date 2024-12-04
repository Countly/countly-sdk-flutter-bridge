import 'package:countly_flutter_np/countly_flutter.dart';
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

    final id = await testDeviceID(isNot('test'));
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
    await testLastRequestParams({'device_id': id});
  });
}
