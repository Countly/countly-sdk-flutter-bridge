import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// Starts a server on [port] that answers every request with success, adds its parameters to [requests]
/// and its path to [paths].
Future<HttpServer> _startServer(int port, List<Map<String, List<String>>> requests, List<String> paths) async {
  final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen((HttpRequest request) async {
    paths.add(request.uri.path);
    String query = request.uri.query;
    if (request.method == 'POST') {
      query = await utf8.decoder.bind(request).join();
    }
    requests.add(Uri(query: query).queryParametersAll);
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'result': 'Success'}));
    await request.response.close();
  });
  return server;
}

/// The keys of the events [request] carries, or an empty list when it carries none.
List<String> _eventKeys(Map<String, List<String>> request) {
  final String? events = request['events']?.first;
  if (events == null) {
    return [];
  }
  return (jsonDecode(events) as List<dynamic>).map((dynamic event) => (event as Map<String, dynamic>)['key'] as String).toList();
}

/// The index of the first request in [requests] that carries the parameter [name], or -1.
int _indexWith(List<Map<String, List<String>>> requests, String name) => requests.indexWhere((Map<String, List<String>> request) => request.containsKey(name));

/// The SDK starts on a server nothing listens on, so its requests and a recorded event wait, and
/// "flushQueues" discards both. Then the requests follow "changeServerUrl" to server A and, with a
/// trailing "/" that is removed, to server B. "changeAppKey" ends the session with the old key at B and
/// begins one with the new key, which the later events carry too. The native SDKs check the values: an
/// empty one is ignored.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Requests follow the changed server URL and app key, and flushed ones are never sent', (WidgetTester tester) async {
    final List<Map<String, List<String>>> requestsA = [];
    final List<Map<String, List<String>>> requestsB = [];
    final List<String> pathsB = [];
    final HttpServer serverA = await _startServer(TEST_SERVER_PORT, requestsA, []);
    final HttpServer serverB = await _startServer(TEST_SERVER_PORT + 1, requestsB, pathsB);

    await Countly.initWithConfig(CountlyConfig('http://0.0.0.0:9', APP_KEY).setLoggingEnabled(true));
    await Countly.instance.events.recordEvent('flushed');
    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 2));
    await Countly.instance.events.recordEvent('flushed_from_event_queue');
    expect(await getRequestQueue(), isNotEmpty);
    expect(await getEventQueue(), isNotEmpty);

    await Countly.instance.flushQueues();
    expect(await getRequestQueue(), isEmpty);
    expect(await getEventQueue(), isEmpty);

    await Countly.instance.changeServerUrl(TEST_SERVER_URL);
    await Countly.instance.events.recordEvent('on_server_a');
    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 3));

    await Countly.instance.changeServerUrl('http://0.0.0.0:${TEST_SERVER_PORT + 1}/');
    await Countly.instance.changeServerUrl('');
    await Countly.instance.changeAppKey('NEW_APP_KEY');
    await Countly.instance.changeAppKey('');
    await Countly.instance.events.recordEvent('on_server_b');
    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 3));
    await serverA.close(force: true);
    await serverB.close(force: true);

    final List<Map<String, List<String>>> all = [...requestsA, ...requestsB];
    expect(all.expand(_eventKeys), isNot(contains('flushed')));
    expect(all.expand(_eventKeys), isNot(contains('flushed_from_event_queue')));
    expect(pathsB, isNotEmpty);
    expect(pathsB.where((String path) => path.startsWith('//')), isEmpty);

    final List<Map<String, List<String>>> eventsA = requestsA.where((Map<String, List<String>> request) => _eventKeys(request).isNotEmpty).toList();
    expect(eventsA.expand(_eventKeys), contains('on_server_a'));
    expect(eventsA.expand(_eventKeys), isNot(contains('on_server_b')));
    expect(eventsA.every((Map<String, List<String>> request) => request['app_key']!.first == APP_KEY), isTrue);

    final int end = _indexWith(requestsB, 'end_session');
    final int begin = _indexWith(requestsB, 'begin_session');
    final int onB = requestsB.indexWhere((Map<String, List<String>> request) => _eventKeys(request).contains('on_server_b'));
    expect(end, isNonNegative);
    expect(requestsB[end]['app_key']!.first, APP_KEY);
    expect(begin, greaterThan(end));
    expect(requestsB[begin]['app_key']!.first, 'NEW_APP_KEY');
    expect(onB, greaterThan(end));
    expect(requestsB[onB]['app_key']!.first, 'NEW_APP_KEY');
    expect(requestsB[onB]['device_id']!.first, requestsB[end]['device_id']!.first);
  });
}
