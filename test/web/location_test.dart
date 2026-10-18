@TestOn('browser')
library location_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// The location parameters of the last queued request that carries events.
Future<Map<String, dynamic>> locationOfLastEventRequest() async {
  final Map<String, dynamic> request = (await requestsWith('events')).last;
  return {
    for (final String name in ['country_code', 'city', 'ip_address', 'location'])
      if (request.containsKey(name)) name: request[name],
  };
}

void main() {
  setUpWebPlugin();

  test('The init location and a later setUserLocation are sent with the requests that follow', () async {
    await Countly.initWithConfig(testConfig()..setLocation(countryCode: 'TR', city: 'Istanbul', gpsCoordinates: '41.0,28.9', ipAddress: '10.0.0.1'));
    await Countly.instance.events.recordEvent('first');
    await waitForHeartbeat();
    expect(await locationOfLastEventRequest(), {'country_code': 'TR', 'city': 'Istanbul', 'ip_address': '10.0.0.1'});

    await Countly.setUserLocation(countryCode: 'DE', city: 'Berlin', gpsCoordinates: '52.5,13.4');
    await Countly.instance.events.recordEvent('second');
    await waitForHeartbeat();
    expect(await locationOfLastEventRequest(), {'country_code': 'DE', 'city': 'Berlin'});
  });

  test('disableLocation stops sending the location values', () async {
    await Countly.initWithConfig(testConfig()..setLocation(countryCode: 'TR', city: 'Istanbul', ipAddress: '10.0.0.1'));

    await Countly.disableLocation();
    await Countly.instance.events.recordEvent('after_disable');
    await waitForHeartbeat();
    expect(await locationOfLastEventRequest(), isEmpty);
  });
}
