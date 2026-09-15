import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

///This test calls all features possible
///It is base test, tries to show how features working without SBS and defaults
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200D_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {'st': false, 'cet': false, 'vt': false, 'eqs': 5, 'lt': false, 'crt': false, 'bom_at': 5, 'bom_d': 30, 'bom_rqp': 0.001, 'bom_ra': 1}
    });
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await callAllFeatures();

    List<String> RQ = await getRequestQueue();
    List<String> EQ = await getEventQueue();
    expect(RQ.length, 0);
    expect(EQ.length, 0);
    deduplicateRequestArray(requestArray);
    validateRequestCounts({'events': 1, 'location': 1, 'crash': 0, 'begin_session': 0, 'consent': 0, 'end_session': 0, 'session_duration': 0, 'apm': 2, 'user_details': 1}, requestArray);
    validateInternalEventCounts({'nps': 1}, requestArray);
    validateImmediateCounts({'hc': 1, 'sc': 1, 'feedback': 1, 'queue': 2, 'ab': 1, 'ab_opt_out': 1, 'rc': 1}, requestArray);

    recordReservedEvent('[CLY]_orientation', {'mode': 'portrait'});
    recordReservedEvent('[CLY]_orientation', {'mode': 'landscape'});
    recordReservedEvent('[CLY]_star_rating', {'platform': 'Web', 'app_version': '1.0', 'widget_id': 'starRatingID', 'closed': false, 'rating': 5, 'comment': 'Loved it!'});
    recordReservedEvent('[CLY]_star_rating', {'platform': 'Android', 'app_version': '1.0', 'widget_id': 'starRatingID', 'closed': false, 'rating': 3, 'comment': 'Meh'});
    EQ = await getEventQueue();
    expect(EQ.length, 4);

    recordReservedEvent('[CLY]_star_rating', {'platform': 'iOS', 'app_version': '1.0', 'widget_id': 'starRatingID', 'closed': false, 'rating': 1, 'comment': 'NO'});
    EQ = await getEventQueue();
    expect(EQ.length, 0); // validate that event queue is cleared when hit the limit and recording internal events are not affected by the custom event tracking disablement
    await Future.delayed(const Duration(seconds: 2));
    deduplicateRequestArray(requestArray);
    validateInternalEventCounts({'nps': 1, 'star_rating': 3, 'orientation': 2}, requestArray);

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {'st': false, 'cet': false, 'vt': false, 'eqs': 5, 'lt': false, 'crt': false, 'bom_at': 5, 'bom_d': 30, 'bom_rqp': 0.001, 'bom_ra': 1}
    });

    await Countly.instance.content.exitContentZone();
    requestArray.clear();

    sbsServerDelay = 5;
    storeRequest({'first': 'true', 'device_id': 'device_id_200C', 'app_key': APP_KEY, 'timestamp': DateTime.now().subtract(const Duration(minutes: 65)).millisecondsSinceEpoch.toString()}); // this will be not backed off because ra 1
    await Countly.recordNetworkTrace('Network Trace', 203, 123, 421, 542, 564); // this will be not backed off because rqp 0.001
    await Countly.recordNetworkTrace('Network Trace', 200, 500, 600, 100, 150); // backoff will trigger here
    await Countly.recordNetworkTrace('Network Trace', 201, 350, 222, 333, 111); // this will be backed off for 30 seconds
    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 15));

    validateRequestCounts({'apm': 2, 'first': 1}, requestArray);
    await Countly.instance.attemptToSendStoredRequests(); // this will not take effect
    await Future.delayed(const Duration(seconds: 5));
    validateRequestCounts({'apm': 2, 'first': 1}, requestArray);

    await Future.delayed(const Duration(seconds: 40));
    validateRequestCounts({'apm': 3, 'first': 1}, requestArray);
  });
}
