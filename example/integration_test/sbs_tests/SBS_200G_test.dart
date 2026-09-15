import 'dart:convert';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

/// Event + Segmentation Whitelist + User Property Whitelist Test
/// Tests: ew (event whitelist), sw (segmentation whitelist), esb (event segmentation blacklist), upw (user property whitelist)
/// - Event whitelist allows ONLY listed events to be recorded
/// - Segmentation whitelist allows ONLY listed segmentation keys globally
/// - Event segmentation blacklist blocks specific segmentation keys per event
/// - User property whitelist allows ONLY listed user properties
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200G_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {
        'ew': ['allowed_event', 'special_event'],
        'sw': ['country', 'platform'],
        'esb': {
          'special_event': ['platform'],
        },
        'upw': ['allowed_custom'],
      },
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Countly.giveAllConsent();
    await Future.delayed(const Duration(seconds: 4));

    // Record events — only whitelisted ones should pass
    await Countly.instance.events.recordEvent('allowed_event', {'country': 'TR', 'age': '25', 'platform': 'mobile'});
    await Countly.instance.events.recordEvent('blocked_by_whitelist', {'country': 'US'}); // not in whitelist, should be blocked
    await Countly.instance.events.recordEvent('special_event', {'country': 'DE', 'platform': 'web', 'extra': 'data'});

    // Set custom user properties — upw only applies to custom properties, not standard fields (name, email, phone etc.)
    await Countly.instance.userProfile.setProperty('allowed_custom', 'visible');
    await Countly.instance.userProfile.setProperty('blocked_custom', 'hidden');
    await Countly.instance.userProfile.save();

    await Countly.instance.sessions.beginSession();
    await Future.delayed(const Duration(seconds: 1));
    await Countly.instance.sessions.endSession();

    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 5));

    // Validate events
    List<Map<String, dynamic>> allEvents = [];
    for (var request in requestArray) {
      if (request.containsKey('events')) {
        List<Map<String, dynamic>> events = (jsonDecode(request['events']![0]) as List).cast<Map<String, dynamic>>();
        allEvents.addAll(events);
      }
    }

    // Event whitelist: only allowed_event and special_event should exist
    List<String> eventKeys = allEvents.map((e) => e['key'] as String).toList();
    expect(eventKeys.contains('allowed_event'), isTrue, reason: 'allowed_event should pass event whitelist');
    expect(eventKeys.contains('special_event'), isTrue, reason: 'special_event should pass event whitelist');
    expect(eventKeys.contains('blocked_by_whitelist'), isFalse, reason: 'blocked_by_whitelist should be filtered by event whitelist');

    // Segmentation whitelist: only country and platform should remain in segmentation
    var allowedEvent = allEvents.firstWhere((e) => e['key'] == 'allowed_event');
    expect(allowedEvent['segmentation']['country'], 'TR');
    expect(allowedEvent['segmentation']['platform'], 'mobile');
    expect(allowedEvent['segmentation'].containsKey('age'), isFalse, reason: 'age should be filtered by segmentation whitelist');

    // Event segmentation blacklist: special_event should have platform blocked
    var specialEvent = allEvents.firstWhere((e) => e['key'] == 'special_event');
    expect(specialEvent['segmentation']['country'], 'DE');
    expect(specialEvent['segmentation'].containsKey('platform'), isFalse, reason: 'platform should be filtered by event segmentation blacklist for special_event');
    expect(specialEvent['segmentation'].containsKey('extra'), isFalse, reason: 'extra should be filtered by segmentation whitelist');

    // Validate user property whitelist — upw applies to custom properties only
    for (var request in requestArray) {
      if (request.containsKey('user_details')) {
        Map<String, dynamic> userDetails = jsonDecode(request['user_details']![0]);
        if (userDetails['custom'] != null && userDetails['custom'] is Map) {
          Map<String, dynamic> custom = Map<String, dynamic>.from(userDetails['custom']);
          expect(custom.containsKey('blocked_custom'), isFalse, reason: 'blocked_custom should be filtered by user property whitelist');
          // allowed_custom should be present
          if (custom.containsKey('allowed_custom')) {
            expect(custom['allowed_custom'], 'visible');
          }
        }
      }
    }

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {
        'ew': ['allowed_event', 'special_event'],
        'sw': ['country', 'platform'],
        'esb': {
          'special_event': ['platform'],
        },
        'upw': ['allowed_custom'],
      },
    });
  });
}
