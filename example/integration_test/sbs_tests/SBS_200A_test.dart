import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200A_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {'lkl': 5, 'lvs': 5, 'lsv': 5, 'lbc': 5, 'ltlpt': 5, 'ltl': 5, 'rcz': false, 'ecz': true, 'czi': 16, 'bom': false, 'dort': 1}
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);

    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    storeRequest({'first': 'true', 'device_id': 'device_id_200C', 'app_key': APP_KEY, 'timestamp': DateTime.now().subtract(const Duration(minutes: 65)).millisecondsSinceEpoch.toString()});
    storeRequest({'second': 'true', 'device_id': 'device_id_200C', 'app_key': APP_KEY, 'timestamp': DateTime.now().subtract(const Duration(minutes: 45)).millisecondsSinceEpoch.toString()});

    List<Map<String, List<String>>> RQ = await getRequestQueueParsed();
    validateRequestCounts({'first': 1, 'second': 1}, RQ); // validate that requests are stored correctly

    await callAllFeatures(disableEnterContent: true);
    RQ = await getRequestQueueParsed();
    expect(RQ.length, 0);
    deduplicateRequestArray(requestArray);
    validateRequestCounts({'first': 0, 'second': 1, 'events': Platform.isAndroid ? 3 : 2, 'location': 1, 'crash': 2, 'begin_session': 1, 'end_session': 1, 'session_duration': 2, 'apm': 2, 'user_details': 1, 'consent': 0}, requestArray);
    // validate that first request is deleted from the queue because of dort: 1
    validateInternalEventCounts({'orientation': 1, 'view': Platform.isAndroid ? 6 : 5, 'nps': 1}, requestArray); // 6 android
    // enter content zone is not called, but a content zone request is sent it is because server config is set cz to true
    validateImmediateCounts({'hc': 1, 'sc': 1, 'feedback': 1, 'queue': 2, 'ab': 1, 'ab_opt_out': 1, 'rc': 1}, requestArray);

    for (var queryParams in requestArray) {
      if (queryParams.containsKey('method') || queryParams.containsKey('hc') || queryParams.containsKey('second')) {
        continue; // skip immediate requests
      }
      testCommonRequestParams(queryParams); // checks general params
      if (queryParams.containsKey('apm')) {
        Map<String, dynamic> apm = json.decode(queryParams['apm']![0]);
        expect(apm['name'].toString().length <= 5, isTrue);
      } else if (queryParams.containsKey('crash')) {
        Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        Map<String, dynamic> crashDetails = crash['_custom'];
        expect(crashDetails.length <= 5, isTrue);
        List<String> logs = (crash['_logs'] as String).split('\n').where((line) => line.trim().isNotEmpty).toList();
        expect(logs.length <= 5, isTrue);
        for (var log in logs) {
          expect(log.length <= 5, isTrue);
        }
        // iOS crash limits are not applied to the stack trace
        if (Platform.isAndroid) {
          List<String> stackTraces = crash['_error'].split('\n');
          for (var stackTrace in stackTraces) {
            expect(stackTrace.length <= 5, isTrue);
          }
        }

        for (var key in crashDetails.keys) {
          expect(key.length <= 5, isTrue);
          expect(crashDetails[key].toString().length <= 5, isTrue);
        }
      } else if (queryParams.containsKey('events')) {
        var eventRaw = json.decode(queryParams['events']![0]);
        for (var event in eventRaw) {
          validateInternalLimitsForEvents(event, 5, 5, 5);
        }
      } else if (queryParams.containsKey('user_details')) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        if (userDetails['custom'] != null && userDetails['custom'].length <= 2) {
          // operators are not truncated with segmentation values limit
          expect((userDetails['custom'].values.where((v) => v is! Map).length ?? 0) <= 5, isTrue);
          expect(userDetails['custom']['speci'], 'somet');
          expect(userDetails['custom']['not_s'], 'somet');
        }

        if (userDetails['custom'] != null && userDetails['custom'].length > 2) {
          checkUnchangingUserData(userDetails, 5, 5);
        }

        if (userDetails['custom'] == null || userDetails['custom'].length > 2) {
          checkUnchangingUserPropeties(userDetails, 5);
        }
      }
    }

    await Countly.instance.content.refreshContentZone(); // this will not affect because refresh disabled
    validateImmediateCounts({'hc': 1, 'sc': 1, 'feedback': 1, 'queue': 2, 'ab': 1, 'ab_opt_out': 1, 'rc': 1}, requestArray);

    await Countly.instance.content.exitContentZone();
    requestArray.clear();

    sbsServerDelay = 11;

    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.endSession(); // this will not be backed off because backoff disabled
    await Future.delayed(const Duration(seconds: 10)); // wait for sdk to process and get the result from server

    await Countly.instance.attemptToSendStoredRequests(); // this will take affect and trigger sending the requests
    await Future.delayed(const Duration(seconds: 2));

    validateRequestCounts({'begin_session': 1, 'end_session': 1}, requestArray);
    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {'lkl': 5, 'lvs': 5, 'lsv': 5, 'lbc': 5, 'ltlpt': 5, 'ltl': 5, 'rcz': false, 'ecz': true, 'czi': 16, 'bom': false, 'dort': 1}
    });
  });
}
