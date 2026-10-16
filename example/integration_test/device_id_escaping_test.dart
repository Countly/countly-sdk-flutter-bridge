import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils.dart';

/// A device ID with characters that need URL encoding comes back from getID exactly as it was
/// set, so passing it back to the SDK keeps the same user.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('getID returns device IDs with special characters as they were set', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));

    await Countly.instance.deviceId.changeWithoutMerge('user@example.com');
    final String? firstID = await Countly.instance.deviceId.getID();
    expect(firstID, 'user@example.com');

    // Setting the ID that getID returned must not create another user.
    await Countly.instance.deviceId.changeWithoutMerge(firstID!);
    expect(await Countly.instance.deviceId.getID(), 'user@example.com');

    await Countly.instance.deviceId.changeWithoutMerge('first last+tag/1@example.com');
    expect(await Countly.instance.deviceId.getID(), 'first last+tag/1@example.com');
  });
}
