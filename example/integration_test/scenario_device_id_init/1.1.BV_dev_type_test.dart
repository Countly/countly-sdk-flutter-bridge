import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 1.1.Test Device ID Type - Bad Value - Developer sets the ID during init
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('1.1.Test Device ID Type - Bad Value - Developer sets the ID during init', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('');
    await Countly.initWithConfig(config);

    final id = await testDeviceID(isNot(''));
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
    await testLastRequestParams({'device_id': id});
  });
}
