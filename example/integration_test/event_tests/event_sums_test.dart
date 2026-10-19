import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// Event sums keep their exact value on the way to the native SDKs, and the deprecated map
/// calls read whole-number and text values instead of falling back to 0 or 1.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Event sums and counts reach the event queue unchanged', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    // Keys are unique per run because the event queue survives between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    await Countly.instance.events.recordEvent('precise_sum_$run', null, 1, 19.99);
    await Countly.instance.events.recordEvent('large_sum_$run', null, 1, 12345678.99);
    await Countly.recordEvent({'key': 'map_int_sum_$run', 'sum': 10});
    await Countly.recordEvent({'key': 'map_text_values_$run', 'sum': '19.99', 'count': '3', 'duration': '2'});
    await Countly.recordEvent({'key': 'map_double_sum_$run', 'sum': 4.5, 'count': 2});
    await Countly.startEvent('map_timed_$run');
    await Countly.endEvent({'key': 'map_timed_$run', 'sum': '7', 'count': 4});

    final Map<String, Map<String, dynamic>> events = {};
    for (final String rawEvent in await getEventQueue()) {
      final Map<String, dynamic> event = json.decode(rawEvent);
      events[event['key'] as String] = event;
    }
    print('EQ events for this run: ${events.keys.where((key) => key.endsWith(run)).toList()}');

    expect(events['precise_sum_$run']!['sum'], 19.99);
    expect(events['large_sum_$run']!['sum'], 12345678.99);

    expect(events['map_int_sum_$run']!['sum'], 10);
    expect(events['map_int_sum_$run']!['count'], 1);

    expect(events['map_text_values_$run']!['sum'], 19.99);
    expect(events['map_text_values_$run']!['count'], 3);
    expect(events['map_text_values_$run']!['dur'], 2);

    expect(events['map_double_sum_$run']!['sum'], 4.5);
    expect(events['map_double_sum_$run']!['count'], 2);

    expect(events['map_timed_$run']!['sum'], 7);
    expect(events['map_timed_$run']!['count'], 4);
  });
}
