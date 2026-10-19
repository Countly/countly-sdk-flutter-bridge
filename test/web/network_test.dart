@TestOn('browser')
library network_test;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('Custom headers from the config are sent, and runtime ones are added to them', () async {
    final List<Map<String, String>> sent = recordSentHeaders();
    await Countly.initWithConfig(testConfig()..setCustomNetworkRequestHeaders({'X-Tenant': 'acme', 'X-Version': '1'}));
    await waitForHeartbeat();

    expect(sent, isNotEmpty);
    expect(sent.first, containsPair('X-Tenant', 'acme'));
    expect(sent.first, containsPair('X-Version', '1'));

    await Countly.instance.addCustomNetworkRequestHeaders({'X-Version': '2', 'X-Trace': 'abc'});
    final Object? headers = (webInstance()['headers'] as JSObject).dartify();
    expect(headers, {'X-Tenant': 'acme', 'X-Version': '2', 'X-Trace': 'abc'});
  });

  test('attemptToSendStoredRequests moves waiting events into the request queue at once', () async {
    await Countly.initWithConfig(testConfig()..setEventQueueSizeToSend(100));
    await waitForHeartbeat();

    await Countly.instance.events.recordEvent('waiting');
    await Countly.instance.attemptToSendStoredRequests();

    expect(await eventQueue(), isEmpty);
    expect((await queuedEvents()).where((e) => e['key'] == 'waiting'), hasLength(1));
  });
}
