import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// The deprecated "storedRequestsLimit" has no effect, so the request queue still keeps every
/// request while the server is unreachable.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('storedRequestsLimit does not limit the request queue', (WidgetTester tester) async {
    expect(await Countly.storedRequestsLimit(), 'storedRequestsLimit: deprecated, no effect');
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY)
      ..setLoggingEnabled(true)
      ..enableManualSessionHandling());
    // Values are unique per run because the request queue survives between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    await Countly.instance.sessions.beginSession();
    await Countly.instance.userProfile.setProperty('first_$run', 1);
    await Countly.instance.userProfile.save();
    await Countly.instance.userProfile.setProperty('second_$run', 2);
    await Countly.instance.userProfile.save();
    await Countly.instance.sessions.endSession();
    await Future<void>.delayed(const Duration(seconds: 2));

    final List<String> requests = await getRequestQueue();
    expect(requests.where((request) => request.contains('first_$run')).length, 1);
    expect(requests.where((request) => request.contains('second_$run')).length, 1);
    expect(requests.where((request) => request.contains('end_session=1')).length, greaterThanOrEqualTo(1));
  });
}
