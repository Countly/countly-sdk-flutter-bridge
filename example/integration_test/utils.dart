import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channelTest = MethodChannel('countly_flutter');

// Base config options for tests
final String SERVER_URL = 'https://xxx.count.ly';
final String APP_KEY = 'YOUR_APP_KEY'; // change this for ios tests

/// Get request queue from native side (list of strings)
Future<List<String>> getRequestQueue() async {
  final List<dynamic> rq = await _channelTest.invokeMethod('getRequestQueue');
  return rq.cast<String>();
}

/// Get event queue from native side (list of json objects)
Future<List<String>> getEventQueue() async {
  final List<dynamic> eq = await _channelTest.invokeMethod('getEventQueue');
  return eq.cast<String>();
}

/// Verify the common request queue parameters
void testCommonRequestParams(Map<String, List<String>> requestObject) {
  expect(requestObject['app_key']?[0], APP_KEY);
  expect(requestObject['sdk_name']?[0], "dart-flutterb-${Platform.isIOS ? "ios" : "android"}");
  expect(requestObject['sdk_version']?[0], '24.1.0');
  expect(requestObject['av']?[0], Platform.isIOS ? '0.0.1' : '1.0.0');
  assert(requestObject['timestamp']?[0] != null);

  expect(requestObject['hour']?[0], DateTime.now().hour.toString());
  expect(requestObject['dow']?[0], DateTime.now().weekday.toString());
  expect(requestObject['tz']?[0], DateTime.now().timeZoneOffset.inMinutes.toString());
}

/// Start a server to receive the requests from the SDK and store them in a provided List
/// Use http://0.0.0.0:8080 as the server url
void creatServer(List requestArray) async {
  // Start a server to receive the requests from the SDK
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  server.listen((HttpRequest request) {
    print(request.uri.queryParametersAll.toString());

    // Store the request parameters for later verification
    requestArray.add(request.uri.queryParametersAll);

    // Send a response
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.write(jsonEncode({'result': 'Success'}));
    request.response.close();
  });
}

/// halts the sdk
/// to use this add the following code snippert to your test after ensureInitialized()
//   setUpAll(() async {
//     await halt();
//   });
// Currently it seems like the app is destroyed after each test, so this is not needed
Future<void> halt() async {
  await _channelTest.invokeMethod('halt');
}

/// Get and print elements with wanted param from event queue
/// [String param] - wanted param
Future<List<String>> getAndPrintWantedElementsWithParamFromEventQueue(String param) async {
  List<String> wantedElements = [];
  List<String> eventQueue = await getEventQueue();
  eventQueue.forEach((element) {
    if (element.contains(param)) {
      wantedElements.add(element);
      print('event:[' + element + ']');
    }
  });
  return wantedElements;
}

/// Get and print elements with wanted param from request queue
/// [String param] - wanted param
Future<List<String>> getAndPrintWantedElementsWithParamFromRequestQueue(String param) async {
  List<String> wantedElements = [];
  List<String> requestQueue = await getRequestQueue();
  requestQueue.forEach((element) {
    if (element.contains(param)) {
      wantedElements.add(element);
      print('request:[' + element + ']');
    }
  });
  return wantedElements;
}

/// Get and print elements with wanted param from all queues
/// [String param] - wanted param
Future<List<String>> getAndPrintWantedElementsWithParamFromAllQueues(String param) async {
  List<String> requestQueue = await getAndPrintWantedElementsWithParamFromRequestQueue(param);
  List<String> eventQueue = await getAndPrintWantedElementsWithParamFromEventQueue(param);
  return requestQueue + eventQueue;
}

/// Get apm params from request
/// [String request] - request
Future<Map<String, dynamic>> getApmParamsFromRequest(String request) async {
  Map<String, List<String>> queryParams = Uri.parse("?" + request).queryParametersAll;
  Map<String, dynamic> apmParams = json.decode(queryParams['apm']![0]);
  return apmParams;
}

/// Go to background and foreground
void goBackgroundAndForeground() {
  FlutterForegroundTask.minimizeApp();
  if (Platform.isIOS) {
    printMessageMultipleTimes('will now go to background, get ready to go foreground manually', 3);
  }
  sleep(Duration(seconds: 2));
  FlutterForegroundTask.launchApp();
  if (Platform.isIOS) {
    printMessageMultipleTimes('waiting for 3 seconds, now go to foreground', 3);
  }
  sleep(Duration(seconds: 3));
}

/// Print message x times
/// [String message] - message
/// [int times] - times
void printMessageMultipleTimes(String message, int times) {
  for (int i = 0; i < times; i++) {
    print(message);
  }
}
