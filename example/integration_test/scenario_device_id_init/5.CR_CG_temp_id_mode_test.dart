import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 5.Check if enableTemporaryDeviceIDMode() sets the device ID correctly during init. Consent Required. Consent Given.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('5.Check if enableTemporaryDeviceIDMode() sets the device ID correctly during init', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableTemporaryDeviceIDMode().setRequiresConsent(true).giveAllConsents();
    await Countly.initWithConfig(config);

    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    expect(requestList.length, 2);
    List<String> eventList = await getEventQueue(); // List of strings
    expect(eventList.length, 1); // orientation
  });
}
