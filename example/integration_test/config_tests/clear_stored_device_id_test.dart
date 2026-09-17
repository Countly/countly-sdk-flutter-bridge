import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils.dart';

/// Checks the device ID resolution order when the stored device ID is cleared at init.
/// Seeding a stored device ID before init is only possible on web, where the SDK's storage is
/// reachable from the test; on the mobile platforms "halt" is the only way to end an init and it
/// erases the storage, so those cases cover the resolution order instead.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Countly.instance.halt();
    clearWebLocalStorage();
  });

  testWidgets('Clearing the stored device ID leaves the SDK to generate one', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableClearStoredDeviceId();
    await Countly.initWithConfig(config);

    final id = await testDeviceID(isNotEmpty);
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
    await testLastRequestParams({'device_id': id});
  });

  testWidgets('A provided device ID still wins over clearing the stored one', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableClearStoredDeviceId().setDeviceId('provided_id');
    await Countly.initWithConfig(config);

    await testDeviceID('provided_id');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'provided_id'});
  });

  testWidgets('Temporary ID mode still wins over clearing the stored one', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableClearStoredDeviceId().enableTemporaryDeviceIDMode();
    await Countly.initWithConfig(config);

    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
  });

  testWidgets('A stored device ID is reused when it is not cleared', (WidgetTester tester) async {
    seedWebDeviceID(APP_KEY, 'stored_id');
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));

    await testDeviceID('stored_id');
  }, skip: !kIsWeb);

  testWidgets('A stored device ID is dropped when it is cleared', (WidgetTester tester) async {
    seedWebDeviceID(APP_KEY, 'stored_id');
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableClearStoredDeviceId());

    await testDeviceID(isNot('stored_id'));
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
  }, skip: !kIsWeb);
}
