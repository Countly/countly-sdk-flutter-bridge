import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// using 0.0.0.0 (InternetAddress.anyIPv4) for the server url will start a server on the local machine
final String SERVER_URL = 'http://0.0.0.0:8080';
final String APP_KEY = 'YOUR_APP_KEY';
List reqs = [];

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Start a server to receive the requests from the SDK
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  server.listen((HttpRequest request) {
    print(request.uri.queryParametersAll.toString());

    // Store the request parameters for later verification
    reqs.add(request.uri.queryParametersAll);
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.write(jsonEncode({'result': 'Success'}));
    request.response.close();
  });
  runTests();
}

void runTests() {
  testWidgets('Test the requests coming from the server for some common params', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    // Wait for the requests to be received by the server
    await Future.delayed(Duration(seconds: 5)).then((value) {
      // Verify the requests
      for (var req in reqs) {
        expect(req['app_key'][0], APP_KEY);
        expect(req['sdk_name'][0], 'dart-flutterb-android');
        expect(req['sdk_version'][0], '23.12.0');
      }
    });
  });
}
