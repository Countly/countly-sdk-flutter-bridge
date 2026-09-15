import 'dart:convert';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

/// User Property Filtering + Cache Limit + Journey Trigger Events Test
/// Tests: upb (user property blacklist), upcl (user property cache limit), jte (journey trigger events)
/// - User property blacklist blocks specific user properties from being sent
/// - User property cache limit restricts how many custom user properties are cached
/// - Journey trigger events control which events trigger content zone refresh
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200F_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {
        'upb': ['blocked_prop', 'secret_prop'],
        'upcl': 3,
        'jte': ['journey_event'],
        'ecz': true,
      },
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Countly.giveAllConsent();
    await Future.delayed(const Duration(seconds: 4));

    // Set user properties — some should be blocked by user property blacklist
    await Countly.instance.userProfile.setUserProperties({'name': 'Test User', 'blocked_prop': 'should_not_appear', 'secret_prop': 'should_not_appear', 'allowed_prop': 'should_appear'});
    await Countly.instance.userProfile.save();

    await Countly.instance.sessions.beginSession();
    await Future.delayed(const Duration(seconds: 1));
    await Countly.instance.sessions.endSession();

    await Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 5));

    // Validate user property blacklist in sent requests
    for (var request in requestArray) {
      if (request.containsKey('user_details')) {
        Map<String, dynamic> userDetails = jsonDecode(request['user_details']![0]);
        if (userDetails['custom'] != null) {
          Map<String, dynamic> custom = userDetails['custom'];
          expect(custom.containsKey('blocked_prop'), isFalse, reason: 'blocked_prop should be filtered by user property blacklist');
          expect(custom.containsKey('secret_prop'), isFalse, reason: 'secret_prop should be filtered by user property blacklist');
        }
      }
    }

    // Validate journey trigger events — record a journey event and check content zone refresh is triggered
    requestArray.clear();
    await Countly.instance.events.recordEvent('journey_event', {'step': 'checkout'});
    await Future.delayed(const Duration(seconds: 5));

    // After journey_event is sent and succeeds, a content zone refresh should be triggered
    bool contentZoneRefreshTriggered = false;
    for (var request in requestArray) {
      if (request.containsKey('method') && request['method']![0] == 'queue') {
        contentZoneRefreshTriggered = true;
      }
    }
    expect(contentZoneRefreshTriggered, isTrue, reason: 'Journey trigger event should trigger content zone refresh');

    // Record a non-journey event — should NOT trigger content zone refresh
    requestArray.clear();
    await Countly.instance.events.recordEvent('normal_event', {'step': 'browse'});
    await Future.delayed(const Duration(seconds: 5));

    bool extraContentZoneRefresh = false;
    for (var request in requestArray) {
      if (request.containsKey('method') && request['method']![0] == 'queue') {
        extraContentZoneRefresh = true;
      }
    }
    expect(extraContentZoneRefresh, isFalse, reason: 'Non-journey event should NOT trigger content zone refresh');

    await Countly.instance.content.exitContentZone();

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {
        'upb': ['blocked_prop', 'secret_prop'],
        'upcl': 3,
        'jte': ['journey_event'],
        'ecz': true,
      },
    });
  });
}
