@TestOn('browser')
library attribution_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('Direct attribution is recorded from the config and at runtime, organic without a campaign ID', () async {
    await Countly.initWithConfig(testConfig()..recordDirectAttribution('countly', '{"cid":"init_campaign"}'));

    await Countly.recordDirectAttribution('countly', '{"cid":"runtime_campaign","cuid":"user_7"}');
    await Countly.recordDirectAttribution('countly', 'not json');
    await Countly.recordDirectAttribution('countly', '{"cuid":"no_campaign_id"}');
    await Countly.recordDirectAttribution('_other', '{"cid":"wrong_type"}');
    await waitForHeartbeat();

    final List<Map<String, dynamic>> attributions = await requestsWith('campaign_id');
    expect(attributions.map((r) => r['campaign_id']).toList(), ['init_campaign', 'runtime_campaign', 'cly_organic']);
    expect(attributions[0].containsKey('campaign_user'), isFalse);
    expect(attributions[1]['campaign_user'], 'user_7');
    expect(attributions[2]['campaign_user'], 'no_campaign_id');
  });

  test('Direct attribution needs the attribution consent', () async {
    await Countly.initWithConfig(testConfig()
      ..setRequiresConsent(true)
      ..setConsentEnabled(['events']));

    await Countly.recordDirectAttribution('countly', '{"cid":"blocked"}');
    await waitForHeartbeat();
    expect(await requestsWith('campaign_id'), isEmpty);

    await Countly.giveConsent(['attribution']);
    await Countly.recordDirectAttribution('countly', '{"cid":"allowed"}');
    await waitForHeartbeat();
    expect((await requestsWith('campaign_id')).map((r) => r['campaign_id']).toList(), ['allowed']);
  });
}
