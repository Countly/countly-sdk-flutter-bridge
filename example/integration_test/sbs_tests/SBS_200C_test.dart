import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

/// use auto sessions for showing session update
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200C_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {'networking': false, 'cr': true, 'rqs': 5, 'sui': 10},
    });

    setServerConfig({
      'v': 1,
      't': 1750748806695,
      'c': {'networking': false, 'cr': true, 'rqs': 5, 'sui': 10},
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('device_id_200C');

    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    await callAllFeatures(disableConsentCall: true);

    // Validate that networking is disabled and no requests are sent
    deduplicateRequestArray(requestArray);
    expect(requestArray.length, 1); // only SC request should be sent
    validateImmediateCounts({'sc': 1}, requestArray);
    requestArray.clear(); // clear requestArray to validate the next requests

    // Validate that consent is required and not given and all called features are not created a request
    List<Map<String, List<String>>> rq = await getRequestQueueParsed();
    validateRequestCounts({'consent': 1, 'location': 1}, rq);
    Map<String, dynamic> expectedConsent = {'push': false, 'views': false, 'attribution': false, 'content': false, 'users': false, 'feedback': false, 'apm': false, 'location': false, 'remote-config': false, 'sessions': false, 'crashes': false, 'events': false, 'metrics': false};

    if (Platform.isAndroid) {
      expectedConsent['scrolls'] = false; // Android has scrolls, content, star-rating, clicks consents extra
      expectedConsent['content'] = false;
      expectedConsent['star-rating'] = false;
      expectedConsent['clicks'] = false;
    }

    expect(jsonDecode(rq[0]['consent']![0]), expectedConsent);
    expect(rq[1]['location']![0], '');
    expect(rq.length, 2);

    // Validate that session update occurs in every 10 seconds
    await Countly.giveConsent(['sessions']);
    // after giving this
    // one consent, one begin session and two duration requests should be sent
    // however this adds up to 6 request
    // because our RQ limit is 5 the first consent request where all false is dropped

    await Future.delayed(const Duration(seconds: 25));
    rq = await getRequestQueueParsed();
    expect(rq.length, 5); // 5 request at max could be
    expect(requestArray.length, 0); // none request sent after sc request

    validateRequestCounts({'begin_session': 1, 'session_duration': 2, 'consent': 1, 'location': 2}, rq); // one location is in begin_session
    expect(rq[0]['location']![0], ''); // first request is location request from previous validations, it was consent request before but now location

    expect(rq[1]['begin_session']![0], '1'); // second request is begin session request from auto sessions
    expect(rq[1]['location']![0], ''); // show location is disabled because no consent given with tied to session request

    expectedConsent['sessions'] = true; // now sessions consent is true
    expect(jsonDecode(rq[2]['consent']![0]), expectedConsent); // second request is consent request

    // Session duration values depend on wall-clock timing; allow ±2s tolerance
    int dur1 = int.parse(rq[3]['session_duration']![0]);
    int dur2 = int.parse(rq[4]['session_duration']![0]);
    expect(dur1, inInclusiveRange(3, 7), reason: 'first session_duration ~5s'); // ~5s after begin_session
    expect(dur2, inInclusiveRange(8, 12), reason: 'second session_duration ~10s'); // ~10s after first update

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {'networking': false, 'cr': true, 'rqs': 5, 'sui': 10},
    });
  });
}
