import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// A location with only some of its parts set sends those parts and leaves the others out,
/// instead of sending the text "null" for them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A partial location never sends the text null', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    // Values are unique per run because the request queue survives between runs on a device.
    final String city = 'City_${DateTime.now().millisecondsSinceEpoch}';

    await Countly.setUserLocation(city: city);
    await Countly.setLocation('38.42', '27.14');

    final List<Map<String, String>> requests = [];
    for (final String request in await getRequestQueue()) {
      requests.add(Uri.parse('?$request').queryParameters);
    }
    print('RQ: $requests');

    for (final Map<String, String> request in requests) {
      for (final String key in ['city', 'country_code', 'ip', 'location']) {
        expect(request[key], isNot('null'), reason: 'request $request');
      }
    }
    expect(requests.where((request) => request['city'] == city).length, 1);
    expect(requests.any((request) => isLocation(request['location'], 38.42, 27.14)), isTrue);
  });
}

/// Whether [value] holds the given coordinates. The native SDKs format them differently, for
/// example "38.42,27.14" and "38.420000,27.140000", so the numbers are compared.
bool isLocation(String? value, double latitude, double longitude) {
  final List<String> parts = (value ?? '').split(',');
  return parts.length == 2 && double.tryParse(parts[0]) == latitude && double.tryParse(parts[1]) == longitude;
}
