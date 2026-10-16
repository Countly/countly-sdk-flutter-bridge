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

  test('Views carry global and own segmentation, and the next view ends the previous one', () async {
    await Countly.initWithConfig(testConfig()..setGlobalViewSegmentation({'app': 'shop', 'theme': 'dark'}));

    final String? homeId = await Countly.instance.views.startView('Home', {'theme': 'light', 'tab': 1});
    final String? cartId = await Countly.instance.views.startAutoStoppedView('Cart');
    await waitForHeartbeat();

    expect(homeId, hasLength(21));
    expect(cartId, hasLength(21));
    expect(homeId, isNot(cartId));

    final List<Map<String, dynamic>> events = await viewEvents();
    final Map<String, dynamic> homeStart = events.firstWhere((e) => e['segmentation']['name'] == 'Home' && e['segmentation']['visit'] == 1);
    expect(homeStart['segmentation'], containsPair('app', 'shop'));
    expect(homeStart['segmentation'], containsPair('theme', 'light'));
    expect(homeStart['segmentation'], containsPair('tab', 1));

    final Map<String, dynamic> cartStart = events.firstWhere((e) => e['segmentation']['name'] == 'Cart' && e['segmentation']['visit'] == 1);
    expect(cartStart['segmentation'], containsPair('theme', 'dark'));

    final List<Map<String, dynamic>> homeEnds = events.where((e) => e['segmentation']['name'] == 'Home' && e['dur'] != null).toList();
    expect(homeEnds, hasLength(1));
  });

  test('Stopping by name, by ID and all views ends only the running view', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.instance.views.startView('First');
    await Countly.instance.views.stopViewWithName('Other');
    await Countly.instance.views.stopViewWithName('First');
    await Countly.instance.views.stopViewWithName('First');

    final String? secondId = await Countly.instance.views.startView('Second');
    await Countly.instance.views.stopViewWithID('not-the-id');
    await Countly.instance.views.stopViewWithID(secondId!);

    await Countly.instance.views.startView('Third');
    await Countly.instance.views.stopAllViews();
    await Countly.instance.views.stopAllViews();
    await waitForHeartbeat();

    final List<Map<String, dynamic>> ends = (await viewEvents()).where((e) => e['dur'] != null).toList();
    expect(ends.map((e) => e['segmentation']['name']).toList(), ['First', 'Second', 'Third']);
  });

  test('Global view segmentation can be replaced and extended at runtime', () async {
    await Countly.initWithConfig(testConfig()..setGlobalViewSegmentation({'old': 'value'}));

    await Countly.instance.views.setGlobalViewSegmentation({'plan': 'free'});
    await Countly.instance.views.startView('A');
    await Countly.instance.views.updateGlobalViewSegmentation({'plan': 'pro', 'region': 'eu'});
    await Countly.instance.views.startView('B');
    await waitForHeartbeat();

    final List<Map<String, dynamic>> starts = (await viewEvents()).where((e) => e['segmentation']['visit'] == 1).toList();
    final Map<String, dynamic> a = starts.firstWhere((e) => e['segmentation']['name'] == 'A')['segmentation'] as Map<String, dynamic>;
    final Map<String, dynamic> b = starts.firstWhere((e) => e['segmentation']['name'] == 'B')['segmentation'] as Map<String, dynamic>;
    expect(a, containsPair('plan', 'free'));
    expect(a.containsKey('old'), isFalse);
    expect(b, containsPair('plan', 'pro'));
    expect(b, containsPair('region', 'eu'));
  });
}
