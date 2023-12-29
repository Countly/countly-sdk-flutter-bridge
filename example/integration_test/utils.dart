import 'package:flutter_test/flutter_test.dart';

// Verify the common request parameters
void testCommonRequestParams(Map<String, List<String>> requestObject) {
  expect(requestObject['app_key']?[0], 'YOUR_APP_KEY');
  expect(requestObject['sdk_name']?[0], 'dart-flutterb-android');
  expect(requestObject['sdk_version']?[0], '23.12.0');
  expect(requestObject['av']?[0], '1.0.0');

  assert(requestObject['device_id']?[0] != null);
  assert(requestObject['timestamp']?[0] != null);
  assert(requestObject['checksum256']?[0] != null);

  // healthcheck does not have rr
  if (requestObject['hc'] == null) {
    assert(requestObject['rr']?[0] != null);
  }

  expect(requestObject['hour']?[0], DateTime.now().hour.toString());
  expect(requestObject['dow']?[0], DateTime.now().weekday.toString());
  expect(requestObject['tz']?[0], DateTime.now().timeZoneOffset.inMinutes.toString());
}
