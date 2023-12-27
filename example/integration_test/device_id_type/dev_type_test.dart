import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final String SERVER_URL = 'https://xxx.count.ly';
final String APP_KEY = 'YOUR_APP_KEY';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Test Device ID Type - Dev', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);
    DeviceIdType? type = await Countly.getDeviceIDType();
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
  });
}
