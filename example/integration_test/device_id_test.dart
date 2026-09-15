import 'dart:convert';
import 'dart:html';
import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils.dart';
import 'web_utils_stub.dart' if (dart.library.html) 'web_utils.dart';

/// Web-only device ID change tests.
/// On non-web platforms, a single placeholder test passes so the runner doesn't fail.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    testWidgets('device_id_test (web-only, skipped on native)', (WidgetTester tester) async {
      // This test suite is web-only. On native platforms, this placeholder passes.
    });
    return;
  }

  group("Device ID change tests", () {
    tearDown(() async {
      await Countly.instance.halt();
      clearWebLocalStorage();
    });
    test("Check init time temp mode with setID", () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableTemporaryDeviceIDMode();
      await Countly.initWithConfig(config);

      List<String> requestQueue = await getRequestQueue();
      List<String> eventQueue = await getEventQueue();

      expect(1, requestQueue.length);
      expect(1, eventQueue.length);

      dynamic request = jsonDecode(requestQueue[0]);
      expect("[CLY]_temp_id", request["device_id"]);

      await Countly.recordEvent({"key": "1"});
      await Countly.instance.userProfile.setUserProperties({"name": "name"});

      await Countly.instance.deviceId.setID("new ID");

      await Countly.recordEvent({"key": "2"});

      requestQueue = await getRequestQueue();
      eventQueue = await getEventQueue();

      expect(4, requestQueue.length);
      expect(1, eventQueue.length);

      // observe that all requests got new ID
      for (var request in requestQueue) {
        dynamic req = jsonDecode(request);
        expect("new ID", req["device_id"]);
      }
    });

    test("Check init time temp mode with changeWithoutMerge", () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableTemporaryDeviceIDMode();
      await Countly.initWithConfig(config);

      List<String> requestQueue = await getRequestQueue();
      List<String> eventQueue = await getEventQueue();

      expect(1, requestQueue.length);
      expect(0, eventQueue.length);

      dynamic request = jsonDecode(requestQueue[0]);
      expect("[CLY]_temp_id", request["device_id"]);

      await Countly.recordEvent({"key": "1"});
      await Countly.instance.userProfile.setUserProperties({"name": "name"});

      await Countly.instance.deviceId.changeWithoutMerge("new ID");

      await Countly.recordEvent({"key": "2"});

      requestQueue = await getRequestQueue();
      eventQueue = await getEventQueue();

      expect(4, requestQueue.length);
      expect(1, eventQueue.length);

      // observe that all requests got new ID
      for (var request in requestQueue) {
        dynamic req = jsonDecode(request);
        expect("new ID", req["device_id"]);
      }
    });

    test("Check init time temp mode with changeWithMerge", () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableTemporaryDeviceIDMode();
      await Countly.initWithConfig(config);

      List<String> requestQueue = await getRequestQueue();
      List<String> eventQueue = await getEventQueue();

      expect(1, requestQueue.length);
      expect(0, eventQueue.length);

      dynamic request = jsonDecode(requestQueue[0]);
      expect("[CLY]_temp_id", request["device_id"]);

      await Countly.recordEvent({"key": "1"});
      await Countly.instance.userProfile.setUserProperties({"name": "name"});

      await Countly.instance.deviceId.changeWithMerge("new ID");

      await Countly.recordEvent({"key": "2"});

      requestQueue = await getRequestQueue();
      eventQueue = await getEventQueue();

      expect(4, requestQueue.length);
      expect(1, eventQueue.length);

      // observe that all requests got new ID
      for (var request in requestQueue) {
        dynamic req = jsonDecode(request);
        expect("new ID", req["device_id"]);
      }
    });
  });
}
