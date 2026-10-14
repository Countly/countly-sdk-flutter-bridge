import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// User properties keep their types, predefined keys land in predefined fields, and a second
/// setUserProperties call adds to the custom properties of the first instead of replacing them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('User properties keep their types and predefined keys', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    // Values are unique per run because the request queue survives between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    await Countly.instance.userProfile.setProperty('age', 30);
    await Countly.instance.userProfile.setProperty('vip', true);
    await Countly.instance.userProfile.setProperty('email', 'user_$run@example.com');
    await Countly.instance.userProfile.setUserProperties({'nickname': 'nick_$run'});
    await Countly.instance.userProfile.setUserProperties({'level': 5});
    await Countly.instance.userProfile.save();

    final List<String> requests = await getRequestQueue();
    final String request = requests.lastWhere((request) => request.contains('nick_$run'));
    final Map<String, dynamic> userDetails = json.decode(Uri.parse('?$request').queryParameters['user_details']!);
    print('user_details: $userDetails');

    expect(userDetails['email'], 'user_$run@example.com');
    final Map<String, dynamic> custom = userDetails['custom'];
    expect(custom['age'], 30);
    expect(custom['vip'], true);
    expect(custom['nickname'], 'nick_$run');
    expect(custom['level'], 5);
    expect(custom.containsKey('email'), isFalse);
  });
}
