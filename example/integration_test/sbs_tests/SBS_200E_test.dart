import 'dart:convert';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

/// Event + Segmentation Filtering Test
/// Tests: eb (event blacklist), sb (segmentation blacklist), esw (event segmentation whitelist)
/// - Event blacklist blocks specific custom events from being recorded
/// - Segmentation blacklist removes specific segmentation keys globally
/// - Event segmentation whitelist allows only specific segmentation keys per event
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200E_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {
        'eb': ['blocked_event', 'another_blocked'],
        'sb': ['blocked_key', 'secret_key'],
        'esw': {
          'filtered_event': ['allowed_key1', 'allowed_key2'],
        },
      },
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Countly.giveAllConsent();
    await Future.delayed(const Duration(seconds: 4));

    // Record events — some should be blocked by event blacklist
    await Countly.instance.events.recordEvent('allowed_event', {'country': 'TR', 'blocked_key': 'should_be_removed'});
    await Countly.instance.events.recordEvent('blocked_event', {'country': 'TR'}); // should be blocked entirely
    await Countly.instance.events.recordEvent('another_blocked', {'country': 'TR'}); // should be blocked entirely
    await Countly.instance.events.recordEvent('normal_event', {'country': 'US', 'secret_key': 'hidden', 'visible_key': 'shown'});

    // Record event with event-specific segmentation whitelist
    await Countly.instance.events.recordEvent('filtered_event', {'allowed_key1': 'val1', 'allowed_key2': 'val2', 'not_allowed': 'val3'});

    await Countly.instance.sessions.beginSession();
    await Future.delayed(const Duration(seconds: 1));
    await Countly.instance.sessions.endSession();

    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 5));

    // Validate events in requestArray
    List<Map<String, dynamic>> allEvents = [];
    for (var request in requestArray) {
      if (request.containsKey('events')) {
        List<Map<String, dynamic>> events = (jsonDecode(request['events']![0]) as List).cast<Map<String, dynamic>>();
        allEvents.addAll(events);
      }
    }

    // Validate event blacklist: blocked_event and another_blocked should not exist
    List<String> eventKeys = allEvents.map((e) => e['key'] as String).toList();
    expect(eventKeys.contains('blocked_event'), isFalse, reason: 'blocked_event should be filtered by event blacklist');
    expect(eventKeys.contains('another_blocked'), isFalse, reason: 'another_blocked should be filtered by event blacklist');
    expect(eventKeys.contains('allowed_event'), isTrue, reason: 'allowed_event should pass event blacklist');
    expect(eventKeys.contains('normal_event'), isTrue, reason: 'normal_event should pass event blacklist');
    expect(eventKeys.contains('filtered_event'), isTrue, reason: 'filtered_event should pass event blacklist');

    // Validate segmentation blacklist: blocked_key and secret_key should be removed from all events
    for (var event in allEvents) {
      if (event['segmentation'] != null) {
        Map<String, dynamic> seg = event['segmentation'];
        expect(seg.containsKey('blocked_key'), isFalse, reason: 'blocked_key should be filtered by segmentation blacklist in event ${event['key']}');
        expect(seg.containsKey('secret_key'), isFalse, reason: 'secret_key should be filtered by segmentation blacklist in event ${event['key']}');
      }
    }

    // Validate allowed_event has country but not blocked_key
    var allowedEvent = allEvents.firstWhere((e) => e['key'] == 'allowed_event');
    expect(allowedEvent['segmentation']['country'], 'TR');

    // Validate normal_event has country and visible_key but not secret_key
    var normalEvent = allEvents.firstWhere((e) => e['key'] == 'normal_event');
    expect(normalEvent['segmentation']['country'], 'US');
    expect(normalEvent['segmentation']['visible_key'], 'shown');

    // Validate event segmentation whitelist: filtered_event should only have allowed_key1, allowed_key2
    var filteredEvent = allEvents.firstWhere((e) => e['key'] == 'filtered_event');
    expect(filteredEvent['segmentation']['allowed_key1'], 'val1');
    expect(filteredEvent['segmentation']['allowed_key2'], 'val2');
    expect(filteredEvent['segmentation'].containsKey('not_allowed'), isFalse, reason: 'not_allowed should be filtered by event segmentation whitelist');

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {
        'eb': ['blocked_event', 'another_blocked'],
        'sb': ['blocked_key', 'secret_key'],
        'esw': {
          'filtered_event': ['allowed_key1', 'allowed_key2'],
        },
      },
    });
  });
}
