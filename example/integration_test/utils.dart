import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channelTest = MethodChannel('countly_flutter');

// Base config options for tests
final String SERVER_URL = 'https://xxx.count.ly';
final String APP_KEY = 'YOUR_APP_KEY';

/// Get request queue from native side
Future<List> getRequestQueue() async {
  _channelTest.setMethodCallHandler((call) => Future.value(null));
  String? rq = await _channelTest.invokeMethod('getRequestQueue');
  List<dynamic> requestList = json.decode(rq!);
  return requestList;
}

/// Get event queue from native side
Future<List> getEventQueue() async {
  _channelTest.setMethodCallHandler((call) => Future.value(null));

  String? eq = await _channelTest.invokeMethod('getEventQueue');
  List<dynamic> eventList = json.decode(eq!);
  return eventList;
}

/// Verify the common request queue parameters
void testCommonRequestParams(Map<String, List<String>> requestObject) {
  expect(requestObject['app_key']?[0], 'YOUR_APP_KEY');
  expect(requestObject['sdk_name']?[0], 'dart-flutterb-android');
  expect(requestObject['sdk_version']?[0], '23.12.1');
  expect(requestObject['av']?[0], '1.0.0');
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
