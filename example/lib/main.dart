import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';

/// This or a similar call needs to added to catch and report Dart Errors to Countly,
/// You need to run app inside a Zone
/// and provide the [Countly.recordDartError] callback for [onError()]
void main() {
  runZonedGuarded<Future<void>>(() async {
    runApp(MyApp());
  }, Countly.recordDartError);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Countly.isInitialized().then((bool isInitialized) {
      if (!isInitialized) {
        /// Recommended settings for Countly initialisation
        Countly.setLoggingEnabled(
            true); // Enable countly internal debugging logs
        Countly
            .enableCrashReporting(); // Enable crash reporting to report unhandled crashes to Countly
        Countly.setRequiresConsent(
            true); // Set that consent should be required for features to work.
        Countly.giveConsentInit([
          'location',
          'sessions',
          'attribution',
          'push',
          'events',
          'views',
          'crashes',
          'users',
          'push',
          'star-rating',
          'apm',
          'feedback',
          'remote-config'
        ]);
        Countly.setLocationInit('TR', 'Istanbul', '41.0082,28.9784',
            '10.2.33.12'); // Set user initial location.

        /// Optional settings for Countly initialisation
        Countly.enableParameterTamperingProtection(
            'salt'); // Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request
        Countly.setHttpPostForced(
            false); // Set to 'true' if you want HTTP POST to be used for all requests
        Countly
            .enableApm(); // Enable APM features, which includes the recording of app start time.
        if (Platform.isIOS) {
          Countly.recordAttributionID('ADVERTISING_ID');
        } else {
          Countly
              .enableAttribution(); // Enable to measure your marketing campaign performance by attributing installs from specific campaigns.
        }
        Countly.setRemoteConfigAutomaticDownload((result) {
          print(result);
        }); // Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
        var segment = {'Key': 'Value'};
        Countly.setCustomCrashSegment(
            segment); // Set optional key/value segment added for crash reports.
        Countly.pushTokenType(Countly.messagingMode[
            'TEST']!); // Set messaging mode for push notifications

        Countly.setStarRatingDialogTexts('Title', 'Message', 'Dismiss');

        Countly.init(SERVER_URL, APP_KEY).then((value) {
          Countly.appLoadingFinished();
          Countly.start();

          /// Push notifications settings
          /// Should be call after init
          Countly.onNotification((String notification) {
            print('The notification');
            print(notification);
          }); // Set callback to receive push notifications
          Countly
              .askForNotificationPermission(); // This method will ask for permission, enables push notification and send push token to countly server.;

          Countly
              .giveAllConsent(); // give consent for all features, should be call after init
//        Countly.giveConsent(['events', 'views']); // give consent for some specific features, should be call after init.
        }); // Initialize the countly SDK.
      } else {
        print('Countly: Already initialized.');
      }
    });
  }

  // ignore: non_constant_identifier_names
  static String SERVER_URL = 'https://try.count.ly';
  // ignore: non_constant_identifier_names
  static String APP_KEY = 'YOUR_API_KEY';

  void enableTemporaryIdMode() {
    Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
  }

  void manualSessionHandling() {
    Countly.manualSessionHandling();
  }

  void basicEvent() {
    // example for basic event
    var event = {'key': 'Basic Event', 'count': 1};
    Countly.recordEvent(event);
  }

  void eventWithSum() {
    // example for event with sum
    var event = {
      'key': 'Event With Sum',
      'count': 1,
      'sum': '0.99',
    };
    Countly.recordEvent(event);
  }

  void eventWithSegment() {
    // example for event with segment
    var event = {'key': 'Event With Segment', 'count': 1};
    event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
    Countly.recordEvent(event);
  }

  void eventWithSumSegment() {
    // example for event with segment and sum
    var event = {
      'key': 'Event With Sum And Segment',
      'count': 1,
      'sum': '0.99'
    };
    event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
    Countly.recordEvent(event);
  }

  void endEventBasic() {
    Countly.startEvent('Timed Event');
    Timer timer = Timer(Duration(seconds: 5), () {
      Countly.endEvent({'key': 'Timed Event'});
    });
  }

  void endEventWithSum() {
    Countly.startEvent('Timed Event With Sum');
    Timer timer = Timer(Duration(seconds: 5), () {
      Countly.endEvent({'key': 'Timed Event With Sum', 'sum': '0.99'});
    });
  }

  void endEventWithSegment() {
    Countly.startEvent('Timed Event With Segment');
    Timer timer = Timer(Duration(seconds: 5), () {
      var event = {
        'key': 'Timed Event With Segment',
        'count': 1,
      };
      event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
      Countly.endEvent(event);
    });
  }

  void endEventWithSumSegment() {
    Countly.startEvent('Timed Event With Segment, Sum and Count');
    Timer timer = Timer(Duration(seconds: 5), () {
      var event = {
        'key': 'Timed Event With Segment, Sum and Count',
        'count': 1,
        'sum': '0.99'
      };
      event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
      Countly.endEvent(event);
    });
  }

  void recordViewHome() {
    Map<String, Object> segments = {
      'Cats': 123,
      'Moons': 9.98,
      'Moose': 'Deer'
    };
    Countly.recordView('HomePage', segments);
  }

  void recordViewDashboard() {
    Countly.recordView('Dashboard');
  }

  String makeid() {
    int code = Random().nextInt(999999);
    String random = code.toString();
    print(random);
    return random;
  }

  void setUserData() {
    Map<String, Object> options = {
      'name': 'Name of User',
      'username': 'Username',
      'email': 'User Email',
      'organization': 'User Organization',
      'phone': 'User Contact number',
      'picture': 'https://count.ly/images/logos/countly-logo.png',
      'picturePath': '',
      'gender': 'User Gender',
      'byear': '1989',
    };
    Countly.setUserData(options);
  }

  void setProperty() {
    Countly.setProperty('setProperty', 'My Property');
  }

  void increment() {
    Countly.increment('increment');
  }

  void incrementBy() {
    Countly.incrementBy('incrementBy', 10);
  }

  void multiply() {
    Countly.multiply('multiply', 20);
  }

  void saveMax() {
    Countly.saveMax('saveMax', 100);
  }

  void saveMin() {
    Countly.saveMin('saveMin', 50);
  }

  void setOnce() {
    Countly.setOnce('setOnce', '200');
  }

  void pushUniqueValue() {
    Countly.pushUniqueValue('pushUniqueValue', 'morning');
  }

  void pushValue() {
    Countly.pushValue('pushValue', 'morning');
  }

  void pullValue() {
    Countly.pullValue('pushValue', 'morning');
  }

  //
  void giveMultipleConsent() {
    Countly.giveConsent(['events', 'views', 'star-rating', 'crashes']);
  }

  void removeMultipleConsent() {
    Countly.removeConsent(['events', 'views', 'star-rating', 'crashes']);
  }

  void giveAllConsent() {
    Countly.giveAllConsent();
  }

  void removeAllConsent() {
    Countly.removeAllConsent();
  }

  void giveConsentSessions() {
    Countly.giveConsent(['sessions']);
  }

  void giveConsentEvents() {
    Countly.giveConsent(['events']);
  }

  void giveConsentViews() {
    Countly.giveConsent(['views']);
  }

  void giveConsentLocation() {
    Countly.giveConsent(['location']);
  }

  void giveConsentCrashes() {
    Countly.giveConsent(['crashes']);
  }

  void giveConsentAttribution() {
    Countly.giveConsent(['attribution']);
  }

  void giveConsentUsers() {
    Countly.giveConsent(['users']);
  }

  void giveConsentPush() {
    Countly.giveConsent(['push']);
  }

  void giveConsentStarRating() {
    Countly.giveConsent(['star-rating']);
  }

  void giveConsentAPM() {
    Countly.giveConsent(['apm']);
  }

  void removeConsentsessions() {
    Countly.removeConsent(['sessions']);
  }

  void removeConsentEvents() {
    Countly.removeConsent(['events']);
  }

  void removeConsentViews() {
    Countly.removeConsent(['views']);
  }

  void removeConsentlocation() {
    Countly.removeConsent(['location']);
  }

  void removeConsentcrashes() {
    Countly.removeConsent(['crashes']);
  }

  void removeConsentattribution() {
    Countly.removeConsent(['attribution']);
  }

  void removeConsentusers() {
    Countly.removeConsent(['users']);
  }

  void removeConsentpush() {
    Countly.removeConsent(['push']);
  }

  void removeConsentstarRating() {
    Countly.removeConsent(['star-rating']);
  }

  void removeConsentAPM() {
    Countly.removeConsent(['apm']);
  }

  void askForNotificationPermission() {
    Countly.askForNotificationPermission();
  }

  void remoteConfigUpdate() {
    Countly.remoteConfigUpdate((result) {
      print(result);
    });
  }

  void updateRemoteConfigForKeysOnly() {
    Countly.updateRemoteConfigForKeysOnly(['name'], (result) {
      print(result);
    });
  }

  void getRemoteConfigValueForKeyString() {
    Countly.getRemoteConfigValueForKey('stringValue', (result) {
      print(result);
    });
  }

  void getRemoteConfigValueForKeyBoolean() {
    Countly.getRemoteConfigValueForKey('booleanValue', (result) {
      print(result);
    });
  }

  void getRemoteConfigValueForKeyFloat() {
    Countly.getRemoteConfigValueForKey('floatValue', (result) {
      print(result);
    });
  }

  void getRemoteConfigValueForKeyInteger() {
    Countly.getRemoteConfigValueForKey('integerValue', (result) {
      print(result);
    });
  }

  void updateRemoteConfigExceptKeys() {
    Countly.updateRemoteConfigExceptKeys(['url'], (result) {
      print(result);
    });
  }

  void remoteConfigClearValues() {
    Countly.remoteConfigClearValues((result) {
      print(result);
    });
  }

  void getRemoteConfigValueForKey() {
    Countly.getRemoteConfigValueForKey('name', (result) {
      print(result);
    });
  }

  void changeDeviceIdWithMerge() {
    Countly.changeDeviceId('123456', true);
  }

  void changeDeviceIdWithoutMerge() {
    Countly.changeDeviceId('123456', false);
  }

  void enableParameterTamperingProtection() {
    Countly.enableParameterTamperingProtection('salt');
  }

  void setOptionalParametersForInitialization() {
    Map<String, Object> options = {
      'city': 'Tampa',
      'country': 'US',
      'latitude': '28.006324',
      'longitude': '-82.7166183',
      'ipAddress': '255.255.255.255'
    };
    Countly.setOptionalParametersForInitialization(options);
  }

  void addCrashLog() {
    Countly.enableCrashReporting();
    Countly.addCrashLog('User Performed Step A');
    Timer timer = Timer(Duration(seconds: 5), () {
      Countly.logException(
          'one.js \n two.js \n three.js', true, {'_facebook_version': '0.0.1'});
    });
  }

  void causeException() {
    Map<String, Object> options = json.decode('This is a on purpose error.');
    print(options.length);
  }

  void throwException() {
    throw StateError('This is an thrown Dart exception.');
  }

  void throwNativeException() {
    Countly.throwNativeException();
  }

  Future<void> throwExceptionAsync() async {
    Future<void> foo() async {
      throw StateError('This is an async Dart exception.');
    }

    Future<void> bar() async {
      await foo();
    }

    await bar();
  }

  void recordExceptionManually() {
    Countly.logException('This is a manually created exception', true, null);
  }

  void dividedByZero() {
    try {
      int firstInput = 20;
      int secondInput = 0;
      int result = firstInput ~/ secondInput;
      print('The result of $firstInput divided by $secondInput is $result');
    } catch (e, s) {
      print('Exception occurs: $e');
      print('STACK TRACE\n: $s');
      Countly.logExceptionEx(e as Exception, true, stacktrace: s);
    }
  }

  void setLoggingEnabled() {
    Countly.setLoggingEnabled(false);
  }

  void askForStarRating() {
    Countly.askForStarRating();
  }

  void askForFeedback() {
    Countly.askForFeedback('5e391ef47975d006a22532c0', 'Close');
  }

  void showSurvey() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse =
        await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets =
        feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'survey') {
        await Countly.presentFeedbackWidget(widget, 'Cancel');
        break;
      }
    }
  }

  void showNPS() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse =
        await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets =
        feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'nps') {
        await Countly.presentFeedbackWidget(widget, 'Close');
        break;
      }
    }
  }

  void reportSurveyManually() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse =
        await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets =
        feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }
    CountlyPresentableFeedback? chosenWidget;
    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'survey') {
        chosenWidget = widget;
        break;
      }
    }
    List result = await Countly.getFeedbackWidgetData(chosenWidget!);
    error = result[1];
    if (error == null) {
      Map<String, dynamic> retrievedWidgetData = result[0];
      Map<String, Object> segments = {};
      if (retrievedWidgetData != null && retrievedWidgetData.isNotEmpty) {
        List<dynamic> questions = retrievedWidgetData['questions'];

        if (questions != null) {
          Random rnd = Random();
          //iterate over all questions and set random answers
          for (int a = 0; a < questions.length; a++) {
            Map<dynamic, dynamic> question = questions[a];
            String wType = question['type'];
            String questionId = question['id'];
            String answerKey = 'answ-' + questionId;
            List<dynamic> choices = question['choices'];
            switch (wType) {
              //multiple answer question
              case 'multi':
                String str = '';
                for (int b = 0; b < choices.length; b++) {
                  if (b % 2 == 0) {
                    if (b != 0) {
                      str += ',';
                    }
                    str += choices[b]['key'];
                  }
                }
                segments[answerKey] = str;
                break;
              case 'radio':
              //dropdown value selector
              case 'dropdown':
                int pick = rnd.nextInt(choices.length);
                segments[answerKey] =
                    choices[pick]['key']; //pick the key of random choice
                break;
              //text input field
              case 'text':
                segments[answerKey] = 'Some random text';
                break;
              //rating picker
              case 'rating':
                segments[answerKey] = rnd.nextInt(11);
                break;
            }
          }
        }
      }
      await Countly.reportFeedbackWidgetManually(
          chosenWidget, retrievedWidgetData, segments);
    }
  }

  void reportNPSManually() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse =
        await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets =
        feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    CountlyPresentableFeedback? chosenWidget;
    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'nps') {
        chosenWidget = widget;
        break;
      }
    }
    List result = await Countly.getFeedbackWidgetData(chosenWidget!);
    error = result[1];
    if (error == null) {
      Map<String, dynamic> retrievedWidgetData = result[0];
      Map<String, Object> segments = {
        'rating': 3,
        'comment': 'Filled out comment'
      };
      await Countly.reportFeedbackWidgetManually(
          chosenWidget, retrievedWidgetData, segments);
    }
  }

  void setLocation() {
    Countly.setLocation('-33.9142687', '18.0955802');
  }

  // APM Examples
  void startTrace() {
    String traceKey = 'Trace Key';
    Countly.startTrace(traceKey);
  }

  void endTrace() {
    String traceKey = 'Trace Key';
    Map<String, int> customMetric = {'ABC': 1233, 'C44C': 1337};
    Countly.endTrace(traceKey, customMetric);
  }

  List<int> successCodes = [100, 101, 200, 201, 202, 205, 300, 301, 303, 305];
  List<int> failureCodes = [400, 402, 405, 408, 500, 501, 502, 505];

  void recordNetworkTraceSuccess() {
    String networkTraceKey = 'api/endpoint.1';
    var rnd = Random();
    int responseCode = successCodes[rnd.nextInt(successCodes.length)];
    int requestPayloadSize = rnd.nextInt(700) + 200;
    int responsePayloadSize = rnd.nextInt(700) + 200;
    int startTime = DateTime.now().millisecondsSinceEpoch;
    int endTime = startTime + 500;
    Countly.recordNetworkTrace(networkTraceKey, responseCode,
        requestPayloadSize, responsePayloadSize, startTime, endTime);
  }

  void recordNetworkTraceFailure() {
    String networkTraceKey = 'api/endpoint.1';
    var rnd = Random();
    int responseCode = failureCodes[rnd.nextInt(failureCodes.length)];
    int requestPayloadSize = rnd.nextInt(700) + 250;
    int responsePayloadSize = rnd.nextInt(700) + 250;
    int startTime = DateTime.now().millisecondsSinceEpoch;
    int endTime = startTime + 500;
    Countly.recordNetworkTrace(networkTraceKey, responseCode,
        requestPayloadSize, responsePayloadSize, startTime, endTime);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Countly SDK Dart Demo'),
        ),
        body: Center(
            child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              MyButton(
                  text: 'Basic event', color: 'brown', onPressed: basicEvent),
              MyButton(
                  text: 'Event with Sum',
                  color: 'brown',
                  onPressed: eventWithSum),
              MyButton(
                  text: 'Event with Segment',
                  color: 'brown',
                  onPressed: eventWithSegment),
              MyButton(
                  text: 'Even with Sum and Segment',
                  color: 'brown',
                  onPressed: eventWithSumSegment),
              MyButton(
                  text: 'Timed event: Start / Stop',
                  color: 'grey',
                  onPressed: endEventBasic),
              MyButton(
                  text: 'Timed event Sum: Start / Stop',
                  color: 'grey',
                  onPressed: endEventWithSum),
              MyButton(
                  text: 'Timed event Segment: Start / Stop',
                  color: 'grey',
                  onPressed: endEventWithSegment),
              MyButton(
                  text: 'Timed event Sum Segment: Start / Stop',
                  color: 'grey',
                  onPressed: endEventWithSumSegment),
              MyButton(
                  text: "Record View: 'HomePage'",
                  color: 'olive',
                  onPressed: recordViewHome),
              MyButton(
                  text: "Record View: 'Dashboard'",
                  color: 'olive',
                  onPressed: recordViewDashboard),
              MyButton(
                  text: 'Send Users Data',
                  color: 'teal',
                  onPressed: setUserData),
              MyButton(
                  text: 'UserData.setProperty',
                  color: 'teal',
                  onPressed: setProperty),
              MyButton(
                  text: 'UserData.increment',
                  color: 'teal',
                  onPressed: increment),
              MyButton(
                  text: 'UserData.incrementBy',
                  color: 'teal',
                  onPressed: incrementBy),
              MyButton(
                  text: 'UserData.multiply',
                  color: 'teal',
                  onPressed: multiply),
              MyButton(
                  text: 'UserData.saveMax', color: 'teal', onPressed: saveMax),
              MyButton(
                  text: 'UserData.saveMin', color: 'teal', onPressed: saveMin),
              MyButton(
                  text: 'UserData.setOnce', color: 'teal', onPressed: setOnce),
              MyButton(
                  text: 'UserData.pushUniqueValue',
                  color: 'teal',
                  onPressed: pushUniqueValue),
              MyButton(
                  text: 'UserData.pushValue',
                  color: 'teal',
                  onPressed: pushValue),
              MyButton(
                  text: 'UserData.pullValue',
                  color: 'teal',
                  onPressed: pullValue),
              MyButton(
                  text: 'Give multiple consent',
                  color: 'blue',
                  onPressed: giveMultipleConsent),
              MyButton(
                  text: 'Remove multiple consent',
                  color: 'blue',
                  onPressed: removeMultipleConsent),
              MyButton(
                  text: 'Give all Consent',
                  color: 'blue',
                  onPressed: giveAllConsent),
              MyButton(
                  text: 'Remove all Consent',
                  color: 'blue',
                  onPressed: removeAllConsent),
              MyButton(
                  text: 'Give Consent Sessions',
                  color: 'blue',
                  onPressed: giveConsentSessions),
              MyButton(
                  text: 'Give Consent Events',
                  color: 'blue',
                  onPressed: giveConsentEvents),
              MyButton(
                  text: 'Give Consent Views',
                  color: 'blue',
                  onPressed: giveConsentViews),
              MyButton(
                  text: 'Give Consent Location',
                  color: 'blue',
                  onPressed: giveConsentLocation),
              MyButton(
                  text: 'Give Consent Crashes',
                  color: 'blue',
                  onPressed: giveConsentCrashes),
              MyButton(
                  text: 'Give Consent Attribution',
                  color: 'blue',
                  onPressed: giveConsentAttribution),
              MyButton(
                  text: 'Give Consent Users',
                  color: 'blue',
                  onPressed: giveConsentUsers),
              MyButton(
                  text: 'Give Consent Push',
                  color: 'blue',
                  onPressed: giveConsentPush),
              MyButton(
                  text: 'Give Consent starRating',
                  color: 'blue',
                  onPressed: giveConsentStarRating),
              MyButton(
                  text: 'Give Consent Performance',
                  color: 'blue',
                  onPressed: giveConsentAPM),
              MyButton(
                  text: 'Remove Consent Sessions',
                  color: 'blue',
                  onPressed: removeConsentsessions),
              MyButton(
                  text: 'Remove Consent Events',
                  color: 'blue',
                  onPressed: removeConsentEvents),
              MyButton(
                  text: 'Remove Consent Views',
                  color: 'blue',
                  onPressed: removeConsentViews),
              MyButton(
                  text: 'Remove Consent Location',
                  color: 'blue',
                  onPressed: removeConsentlocation),
              MyButton(
                  text: 'Remove Consent Crashes',
                  color: 'blue',
                  onPressed: removeConsentcrashes),
              MyButton(
                  text: 'Remove Consent Attribution',
                  color: 'blue',
                  onPressed: removeConsentattribution),
              MyButton(
                  text: 'Remove Consent Users',
                  color: 'blue',
                  onPressed: removeConsentusers),
              MyButton(
                  text: 'Remove Consent Push',
                  color: 'blue',
                  onPressed: removeConsentpush),
              MyButton(
                  text: 'Remove Consent starRating',
                  color: 'blue',
                  onPressed: removeConsentstarRating),
              MyButton(
                  text: 'Remove Consent Performance',
                  color: 'blue',
                  onPressed: removeConsentAPM),
              MyButton(
                  text: 'Countly.remoteConfigUpdate',
                  color: 'purple',
                  onPressed: remoteConfigUpdate),
              MyButton(
                  text: 'Countly.updateRemoteConfigForKeysOnly',
                  color: 'purple',
                  onPressed: updateRemoteConfigForKeysOnly),
              MyButton(
                  text: 'Countly.updateRemoteConfigExceptKeys',
                  color: 'purple',
                  onPressed: updateRemoteConfigExceptKeys),
              MyButton(
                  text: 'Countly.remoteConfigClearValues',
                  color: 'purple',
                  onPressed: remoteConfigClearValues),
              MyButton(
                  text: 'Get String Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyString),
              MyButton(
                  text: 'Get Boolean Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyBoolean),
              MyButton(
                  text: 'Get Float Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyFloat),
              MyButton(
                  text: 'Get Integer Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyInteger),
              MyButton(
                  text: 'Push Notification',
                  color: 'primary',
                  onPressed: askForNotificationPermission),
              MyButton(
                  text: 'Enable Temporary ID Mode',
                  color: 'violet',
                  onPressed: enableTemporaryIdMode),
              MyButton(
                  text: 'Change Device ID With Merge',
                  color: 'violet',
                  onPressed: changeDeviceIdWithMerge),
              MyButton(
                  text: 'Change Device ID Without Merge',
                  color: 'violet',
                  onPressed: changeDeviceIdWithoutMerge),
              MyButton(
                  text: 'Enable Parameter Tapmering Protection',
                  color: 'violet',
                  onPressed: enableParameterTamperingProtection),
              MyButton(
                  text: 'City, State, and Location',
                  color: 'violet',
                  onPressed: setOptionalParametersForInitialization),
              MyButton(
                  text: 'setLocation', color: 'violet', onPressed: setLocation),
              MyButton(
                  text: 'Send Crash Report',
                  color: 'violet',
                  onPressed: addCrashLog),
              MyButton(
                  text: 'Cause Exception',
                  color: 'violet',
                  onPressed: causeException),
              MyButton(
                  text: 'Throw Exception',
                  color: 'violet',
                  onPressed: throwException),
              MyButton(
                  text: 'Throw Exception Async',
                  color: 'violet',
                  onPressed: throwExceptionAsync),
              MyButton(
                  text: 'Throw Native Exception',
                  color: 'violet',
                  onPressed: throwNativeException),
              MyButton(
                  text: 'Record Exception Manually',
                  color: 'violet',
                  onPressed: recordExceptionManually),
              MyButton(
                  text: 'Divided By Zero Exception',
                  color: 'violet',
                  onPressed: dividedByZero),
              MyButton(
                  text: 'Enabling logging',
                  color: 'violet',
                  onPressed: setLoggingEnabled),
              MyButton(
                  text: 'Open rating modal',
                  color: 'orange',
                  onPressed: askForStarRating),
              MyButton(
                  text: 'Open feedback modal',
                  color: 'orange',
                  onPressed: askForFeedback),
              MyButton(
                  text: 'Show Survey', color: 'orange', onPressed: showSurvey),
              MyButton(text: 'Show NPS', color: 'orange', onPressed: showNPS),
              MyButton(
                  text: 'Report Survey Manually',
                  color: 'orange',
                  onPressed: reportSurveyManually),
              MyButton(
                  text: 'Report NPS Manually',
                  color: 'orange',
                  onPressed: reportNPSManually),
              MyButton(
                  text: 'Start Trace', color: 'black', onPressed: startTrace),
              MyButton(text: 'End Trace', color: 'black', onPressed: endTrace),
              MyButton(
                  text: 'Record Network Trace Success',
                  color: 'black',
                  onPressed: recordNetworkTraceSuccess),
              MyButton(
                  text: 'Record Network Trace Failure',
                  color: 'black',
                  onPressed: recordNetworkTraceFailure),
            ],
          ),
        )),
      ),
    );
  }
}

Map<String, Map<String, Color>> theColor = {
  'default': {'button': Color(0xffe0e0e0), 'text': Color(0xff000000)},
  'red': {'button': Color(0xffdb2828), 'text': Color(0xff000000)},
  'green': {'button': Colors.green, 'text': Color(0xffffffff)},
  'teal': {'button': Color(0xff00b5ad), 'text': Color(0xff000000)},
  'blue': {'button': Color(0xff00b5ad), 'text': Color(0xff000000)},
  'primary': {'button': Color(0xff54c8ff), 'text': Color(0xff000000)},
  'grey': {'button': Color(0xff767676), 'text': Color(0xff000000)},
  'brown': {'button': Color(0xffa5673f), 'text': Color(0xff000000)},
  'purple': {'button': Color(0xffa333c8), 'text': Color(0xff000000)},
  'violet': {'button': Color(0xff6435c9), 'text': Color(0xff000000)},
  'yellow': {'button': Color(0xfffbbd08), 'text': Color(0xffffffff)},
  'black': {'button': Color(0xff1b1c1d), 'text': Color(0xffffffff)},
  'olive': {'button': Color(0xffd9e778), 'text': Color(0xff000000)},
  'orange': {'button': Color(0xffff851b), 'text': Color(0xff000000)}
};

Map<String, Color>? getColor(color) {
  if (color == 'green') {
    return theColor['green'];
  } else if (color == 'teal') {
    return theColor['teal'];
  } else if (color == 'red') {
    return theColor['red'];
  } else if (color == 'brown') {
    return theColor['brown'];
  } else if (color == 'grey') {
    return theColor['grey'];
  } else if (color == 'blue') {
    return theColor['blue'];
  } else if (color == 'purple') {
    return theColor['purple'];
  } else if (color == 'primary') {
    return theColor['primary'];
  } else if (color == 'violet') {
    return theColor['violet'];
  } else if (color == 'black') {
    return theColor['black'];
  } else if (color == 'olive') {
    return theColor['olive'];
  } else if (color == 'orange') {
    return theColor['orange'];
  } else {
    return theColor['default'];
  }
}

class MyButton extends StatelessWidget {
  String? _text;
  Color? _button;
  Color? _textC;
  void Function()? _onPressed;

  MyButton({String? color, String? text, void Function()? onPressed}) {
    _text = text!;

    Map<String, Color>? tColor;
    tColor = getColor(color);
    tColor = tColor ??= theColor['default'];
    _button = tColor?['button'];
    _textC = tColor?['text'];

    _onPressed = onPressed;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: _button,
            padding: EdgeInsets.all(10.0),
            minimumSize: Size(double.infinity, 36)),
        onPressed: _onPressed,
        child: Text(_text!,
            style: TextStyle(color: _textC), textAlign: TextAlign.center));
  }
}
