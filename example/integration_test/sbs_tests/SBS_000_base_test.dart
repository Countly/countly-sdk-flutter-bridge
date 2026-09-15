import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

///This test calls all features possible
///It is base test, tries to show how features working without SBS and defaults
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_000_base', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {});
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await callAllFeatures();

    List<String> RQ = await getRequestQueue();
    List<String> EQ = await getEventQueue();
    expect(RQ.length, 0);
    expect(EQ.length, 0);
    deduplicateRequestArray(requestArray);
    validateRequestCounts({'events': 3, 'location': 1, 'crash': 2, 'begin_session': 1, 'consent': 0, 'end_session': 1, 'session_duration': 2, 'apm': 2, 'user_details': 1}, requestArray);
    validateInternalEventCounts({'orientation': 1, 'view': 6, 'nps': 1}, requestArray);
    validateImmediateCounts({'hc': 1, 'sc': 1, 'feedback': 1, 'queue': 2, 'ab': 1, 'ab_opt_out': 1, 'rc': 1}, requestArray);
  });
}
