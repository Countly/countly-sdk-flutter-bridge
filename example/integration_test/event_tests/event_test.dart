import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import 'event_utils.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK record some events and check what is in the queues', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await generateEvents(); // Generate some events

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, 1);
    expect(eventList.length, Platform.isAndroid ? 33 : 32);

    // begin session
    Map<String, List<String>> queryParams = Uri.parse("?" + requestList[0]).queryParametersAll;
    testCommonRequestParams(queryParams);

    int n = 0;
    Map<String, dynamic> currentEvent;
    if (Platform.isAndroid) {
      currentEvent = json.decode(eventList[n]);
      // 1. orientation event
      expect("[CLY]_orientation", currentEvent['key']);
      expect(1, currentEvent['count']);
      n++;
    }

    // 2. event
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event['key']);

    // 3. event_c
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c['key'] as String, count: event_c['count'] as int);

    // 4. event_c_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_s['key'] as String, count: event_c_s['count'] as int, sum: event_c_s['sum'] as int);

    // 5. event_c_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_d['key'] as String, count: event_c_d['count'] as int, dur: event_c_d['duration'] as int);

    // 6. event_c_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_se['key'] as String, count: event_c_se['count'] as int, segmentation: expectedSegmentation);

    // 7. event_c_s_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_s_d['key'] as String, count: event_c_s_d['count'] as int, sum: event_c_s_d['sum'] as int, dur: event_c_s_d['duration'] as int);

    // 8. event_c_s_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_s_se['key'] as String, count: event_c_s_se['count'] as int, sum: event_c_s_se['sum'] as int, segmentation: expectedSegmentation);

    // 9. event_c_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_d_se['key'] as String, count: event_c_d_se['count'] as int, dur: event_c_d_se['duration'] as int, segmentation: expectedSegmentation);

    // 10. event_c_s_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_c_s_d_se['key'] as String, count: event_c_s_d_se['count'] as int, sum: event_c_s_d_se['sum'] as int, dur: event_c_s_d_se['duration'] as int, segmentation: expectedSegmentation);

    // 11. event_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_s['key'] as String, sum: event_s['sum'] as int);

    // 12. event_s_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_s_d['key'] as String, sum: event_s_d['sum'] as int, dur: event_s_d['duration'] as int);

    // 13. event_s_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_s_se['key'] as String, sum: event_s_se['sum'] as int, segmentation: expectedSegmentation);

    // 14. event_s_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_s_d_se['key'] as String, sum: event_s_d_se['sum'] as int, dur: event_s_d_se['duration'] as int, segmentation: expectedSegmentation);

    // 15. event_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_d['key'] as String, dur: event_d['duration'] as int);

    // 16. event_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_d_se['key'] as String, dur: event_d_se['duration'] as int, segmentation: expectedSegmentation);

    // 17. event_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: event_se['key'] as String, segmentation: expectedSegmentation);

    // 18. timed_event
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event['key'], isTimed: true);

    // 19. timed_event_c
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c['key'] as String, count: 1, isTimed: true);

    // 20. timed_event_c_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_s['key'] as String, count: 1, sum: timed_event_c_s['sum'] as int, isTimed: true);

    // 21. timed_event_c_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_d['key'] as String, count: 1, dur: timed_event_c_d['duration'] as int, isTimed: true);

    // 22. timed_event_c_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_se['key'] as String, count: 1, segmentation: expectedSegmentation, isTimed: true);

    // 23. timed_event_c_s_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_s_d['key'] as String, count: 1, sum: timed_event_c_s_d['sum'] as int, dur: timed_event_c_s_d['duration'] as int, isTimed: true);

    // 24. timed_event_c_s_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_s_se['key'] as String, count: 1, sum: timed_event_c_s_se['sum'] as int, segmentation: expectedSegmentation, isTimed: true);

    // 25. timed_event_c_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_d_se['key'] as String, count: 1, dur: timed_event_c_d_se['duration'] as int, segmentation: expectedSegmentation, isTimed: true);

    // 26. timed_event_c_s_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_c_s_d_se['key'] as String, count: 1, sum: timed_event_c_s_d_se['sum'] as int, dur: timed_event_c_s_d_se['duration'] as int, segmentation: expectedSegmentation, isTimed: true);

    // 27. timed_event_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_s['key'] as String, sum: timed_event_s['sum'] as int, isTimed: true);

    // 28. timed_event_s_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_s_d['key'] as String, sum: timed_event_s_d['sum'] as int, dur: timed_event_s_d['duration'] as int, isTimed: true);

    // 29. timed_event_s_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_s_se['key'] as String, sum: timed_event_s_se['sum'] as int, segmentation: expectedSegmentation, isTimed: true);

    // 30. timed_event_s_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_s_d_se['key'] as String, sum: timed_event_s_d_se['sum'] as int, dur: timed_event_s_d_se['duration'] as int, segmentation: expectedSegmentation, isTimed: true);

    // 31. timed_event_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_d['key'] as String, dur: timed_event_d['duration'] as int, isTimed: true);

    // 32. timed_event_d_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_d_se['key'] as String, dur: timed_event_d_se['duration'] as int, segmentation: expectedSegmentation, isTimed: true);

    // 33. timed_event_se
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: timed_event_se['key'] as String, segmentation: expectedSegmentation, isTimed: true);
  });
}
