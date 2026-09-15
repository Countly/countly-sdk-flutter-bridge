import 'dart:convert';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../event_tests/event_utils.dart';
import '../../utils.dart';
import '../sbs_utils.dart';

/// Test records an event with a key and segmentation values that exceeds the maximum key length set by the SDK's internal limits server SBS limit.
/// - Key length limit is 3, value size is 5 and segmentation values 2 on DP
/// - key length 8, segmentation values 4 in S
/// - Only key length in FS is 8
/// - The event is recorded with the key truncated to 8 #FS
/// - Values in segmentation are truncated to 5 characters #DP
/// - Segmentation values are truncated to 4 characters #S
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_201B_DP_S_FS_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {'lkl': 8},
    });

    setServerConfig({
      'v': 1,
      't': 1750748806695,
      'c': {'lkl': 6, 'lsv': 4},
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    config.sdkInternalLimits.setMaxKeyLength(3).setMaxValueSize(5).setMaxSegmentationValues(2);

    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    await Countly.instance.events.recordEvent('ThisWillCLIPPED_BY_FS', {'no1': 'valueCLIPPED_BY_DP', 'no2': 'valueCLIPPED_BY_DP', 'no3': 'valueCLIPPED_BY_DP', 'no4': 'valueCLIPPED_BY_DP', 'no5': 'valueCLIPPED_BY_DP'});
    List<String> rq = await getRequestQueue();
    List<String> eq = await getEventQueue();
    expect(rq.length, 0);
    expect(eq.length, 1);

    validateEvent(event: jsonDecode(eq.first), key: 'ThisWill', segmentation: {'no1': 'value', 'no4': 'value', 'no3': 'value', 'no5': 'value'});

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {'lkl': 8, 'lsv': 4},
    });
  });
}
