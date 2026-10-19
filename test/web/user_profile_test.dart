@TestOn('browser')
library user_profile_test;

import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// Every user details request in the request queue, decoded.
Future<List<Map<String, dynamic>>> queuedUserDetails() async {
  return (await requestsWith('user_details')).map((Map<String, dynamic> request) => jsonDecode(request['user_details'] as String) as Map<String, dynamic>).toList();
}

void main() {
  setUpWebPlugin();

  test('User properties from the config are sent at init, named and custom ones apart', () async {
    await Countly.initWithConfig(testConfig()..setUserProperties({'name': 'Ada', 'email': 'ada@example.com', 'tier': 'gold'}));
    await waitForHeartbeat();

    final Map<String, dynamic> details = (await queuedUserDetails()).single;
    expect(details['name'], 'Ada');
    expect(details['email'], 'ada@example.com');
    expect(details['custom'], {'tier': 'gold'});
  });

  test('Profile properties are sent at once, and property changes together on save', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.instance.userProfile.setUserProperties({'username': 'ada', 'level': 3});
    await Countly.instance.userProfile.increment('logins');
    await Countly.instance.userProfile.incrementBy('points', 5);
    await Countly.instance.userProfile.multiply('bonus', 2);
    await Countly.instance.userProfile.saveMax('best', 90);
    await Countly.instance.userProfile.saveMin('fastest', 12);
    await Countly.instance.userProfile.setOnce('first_seen', 'today');
    await Countly.instance.userProfile.push('visited', 'home');
    await Countly.instance.userProfile.pushUnique('badges', 'early');
    await Countly.instance.userProfile.pull('wishlist', 'old');
    await Countly.instance.userProfile.save();
    await waitForHeartbeat();

    final List<Map<String, dynamic>> details = await queuedUserDetails();
    expect(details, hasLength(2));
    expect(details.first['username'], 'ada');
    expect(details.first['custom'], {'level': 3});
    final Map<String, dynamic> custom = details.last['custom'] as Map<String, dynamic>;
    expect(custom['logins'], {r'$inc': 1});
    expect(custom['points'], {r'$inc': 5});
    expect(custom['bonus'], {r'$mul': 2});
    expect(custom['best'], {r'$max': 90});
    expect(custom['fastest'], {r'$min': 12});
    expect(custom['first_seen'], {r'$setOnce': 'today'});
    expect(custom['visited'], {
      r'$push': ['home']
    });
    expect(custom['badges'], {
      r'$addToSet': ['early']
    });
    expect(custom['wishlist'], {
      r'$pull': ['old']
    });
  });
}
