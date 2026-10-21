import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// The deprecated "Countly.setProperty" sets a predefined key such as "email" in its predefined
/// field, and any other key as a custom property, on every platform.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Deprecated setProperty routes predefined keys to predefined fields', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    // Values are unique per run because the request queue survives between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    // ignore: deprecated_member_use
    await Countly.setProperty('email', 'legacy_$run@example.com');
    // ignore: deprecated_member_use
    await Countly.setProperty('plan', 'plan_$run');

    final List<String> requests = await getRequestQueue();
    final Map<String, dynamic> details = {};
    final Map<String, dynamic> custom = {};
    for (final String request in requests.where((request) => request.contains(run))) {
      final String? rawDetails = Uri.parse('?$request').queryParameters['user_details'];
      if (rawDetails == null) {
        continue;
      }
      final Map<String, dynamic> userDetails = json.decode(rawDetails);
      details.addAll(userDetails);
      custom.addAll(Map<String, dynamic>.from(userDetails['custom'] ?? {}));
    }
    print('user_details: $details');

    expect(details['email'], 'legacy_$run@example.com');
    expect(custom['plan'], 'plan_$run');
    expect(custom.containsKey('email'), isFalse);
  });
}
