import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final String SERVER_URL = 'http://0.0.0.0:8080';
final String APP_KEY = 'YOUR_APP_KEY';
List reqs = [];

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  server.listen((HttpRequest request) {
    print(request.uri.queryParametersAll.toString());
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
  testWidgets('Test queries formed', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Future.delayed(Duration(seconds: 5)).then((value) {
      for (var req in reqs) {
        expect(req['app_key'][0], APP_KEY);
        expect(req['sdk_name'][0], 'dart-flutterb-android');
        expect(req['sdk_version'][0], '23.12.0');
      }
    });
  });
}
