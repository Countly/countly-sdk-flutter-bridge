@TestOn('browser')
library views_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// The view events in the request queue: starts carry "visit", ends carry a duration.
Future<List<Map<String, dynamic>>> viewEvents() async {
  return (await queuedEvents()).where((Map<String, dynamic> event) => event['key'] == '[CLY]_view').toList();
}

void main() {
  setUpWebPlugin();

  test('Views start with their segmentation and no view ID, and the next view ends the previous one', () async {
    await Countly.initWithConfig(testConfig());

    expect(await Countly.instance.views.startView('Home', {'theme': 'light', 'tab': 1}), isNull);
    expect(await Countly.instance.views.startAutoStoppedView('Cart'), isNull);
    await waitForHeartbeat();

    final List<Map<String, dynamic>> events = await viewEvents();
    final Map<String, dynamic> homeStart = events.firstWhere((e) => e['segmentation']['name'] == 'Home' && e['segmentation']['visit'] == 1);
    expect(homeStart['segmentation'], containsPair('theme', 'light'));
    expect(homeStart['segmentation'], containsPair('tab', 1));
    expect(events.where((e) => e['segmentation']['name'] == 'Cart' && e['segmentation']['visit'] == 1), hasLength(1));
    expect(events.where((e) => e['segmentation']['name'] == 'Home' && e['dur'] != null), hasLength(1));
  });
}
