import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// The deprecated "setOptionalParametersForInitialization" sends the city and country it is given,
/// and no coordinates when none are given.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('setOptionalParametersForInitialization without coordinates sends no location', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    // Values are unique per run because the request queue survives between runs on a device.
    final String city = 'City_${DateTime.now().millisecondsSinceEpoch}';

    await Countly.setOptionalParametersForInitialization({'city': city, 'country': 'TR'});
    await Future<void>.delayed(const Duration(seconds: 2));

    final List<Map<String, String>> requests = [];
    for (final String request in await getRequestQueue()) {
      requests.add(Uri.parse('?$request').queryParameters);
    }
    print('RQ: $requests');

    final Map<String, String> request = requests.singleWhere((request) => request['city'] == city);
    expect(request['country_code'], 'TR');
    expect(request['location'] ?? '', isEmpty);
  });
}
