// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/countly_config.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// This or a similar call needs to added to catch and report Dart Errors to
/// Countly,
/// You need to run the app inside a Zone
/// and provide the [Countly.recordDartError] callback for [onError()]
void main() {
  runZonedGuarded<Future<void>>(() async {
    runApp(
      MaterialApp(
        home: const MyApp(),
        navigatorKey: navigatorKey, // Setting a global key for navigator
      ),
    );
  }, Countly.recordDartError);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();
  final _ratingIdController = TextEditingController();

  /// To Show the device id type in UI, when user tap on 'Get Device Id Type'
  /// button
  String _deviceIdType = '';
  final _enableManualSession = false;

  @override
  void initState() {
    super.initState();
    _ratingIdController.addListener(() {
      setState(() {});
    });
    Countly.isInitialized().then((bool isInitialized) {
      if (!isInitialized) {
        Countly.pushTokenType(
          Countly.messagingMode['TEST']!,
        ); // Set messaging mode for push notifications

        final crashSegment = {'Key': 'Value'};
        final userProperties = {
          'customProperty': 'custom Value',
          'username': 'USER_NAME',
          'email': 'USER_EMAIL'
        };

        final Map<String, String> attributionValues = {};
        if (Platform.isIOS) {
          attributionValues[AttributionKey.IDFA] = 'IDFA';
        } else {
          attributionValues[AttributionKey.AdvertisingID] = 'AdvertisingID';
        }

        const campaignData = '{cid:"[PROVIDED_CAMPAIGN_ID]", cuid:"'
            '[PROVIDED_CAMPAIGN_USER_ID]"}';

        final config = CountlyConfig(SERVER_URL, APP_KEY)
          ..enableCrashReporting() // Enable crash reporting to report
          // unhandled crashes to Countly
          ..setRequiresConsent(true) // Set that consent should be required for
          // features to work.
          ..setConsentEnabled([
            CountlyConsent.sessions,
            CountlyConsent.events,
            CountlyConsent.views,
            CountlyConsent.location,
            CountlyConsent.crashes,
            CountlyConsent.attribution,
            CountlyConsent.users,
            CountlyConsent.push,
            CountlyConsent.starRating,
            CountlyConsent.apm,
            CountlyConsent.feedback,
            CountlyConsent.remoteConfig
          ])
          ..setLocation(
            country_code: 'TR',
            city: 'Istanbul',
            ipAddress: '41.0082,28.9784',
            gpsCoordinates: '10.2.33.12',
          ) // Set user  location.
          ..setCustomCrashSegment(crashSegment)
          ..setUserProperties(userProperties)
          ..recordIndirectAttribution(attributionValues)
          ..recordDirectAttribution('countly', campaignData)
          ..setRemoteConfigAutomaticDownload(true, (error) {
            if (error != null) {
              print(error);
            }
          }) // Set Automatic value download happens when the SDK is initiated
          // or when the device ID is changed.
          ..setRecordAppStartTime(true) // Enable APM features, which includes
          // the recording of app start time.
          ..setStarRatingTextMessage('Message for start rating dialog')
          ..setLoggingEnabled(true) // Enable countly internal debugging logs
          ..setParameterTamperingProtectionSalt('salt') // Set the optional
          // salt to be used for calculating the checksum of requested data
          // which will be sent with each request
          ..setHttpPostForced(false); // Set to 'true' if you want HTTP POST to
        // be used for all requests
        if (_enableManualSession) {
          config.enableManualSessionHandling();
        }
        Countly.initWithConfig(config).then((value) {
          Countly.appLoadingFinished();
          Countly.start();

          /// Push notifications settings
          /// Should be call after init
          Countly.onNotification((String notification) {
            print('The notification');
            print(notification);
          }); // Set callback to receive push notifications
          Countly.askForNotificationPermission(); // This method will ask for
          // permission, enables push notification and send push token to
          // countly server.

          Countly.giveAllConsent(); // give consent for all features, should be
          // call after init
          // Countly.giveConsent(['events', 'views']); // give consent for some
          // specific features, should be call after init.
        }); // Initialize the countly SDK.
      } else {
        print('Countly: Already initialized.');
      }
    });
  }

  // ignore: constant_identifier_names
  static const SERVER_URL = 'https://try.count.ly';

  // ignore: constant_identifier_names
  static const APP_KEY = 'YOUR_API_KEY';

  void enableTemporaryIdMode() {
    Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
  }

  bool isManualSession() {
    if (!_enableManualSession) {
      const snackBar = SnackBar(
        content: Text(
          "Set '_enableManualSession = true' in 'main.dart' to test Manual "
          'Session Handling',
        ),
      );
      _messangerKey.currentState!.showSnackBar(snackBar);
    }
    return _enableManualSession;
  }

  void beginSession() {
    if (isManualSession()) {
      Countly.beginSession();
    }
  }

  void updateSession() {
    if (isManualSession()) {
      Countly.updateSession();
    }
  }

  void endSession() {
    if (isManualSession()) {
      Countly.endSession();
    }
  }

  void basicEvent() {
    // example for basic event
    final event = {'key': 'Basic Event', 'count': 1};
    Countly.recordEvent(event);
  }

  void eventWithSum() {
    // example for event with sum
    final event = {
      'key': 'Event With Sum',
      'count': 1,
      'sum': '0.99',
    };
    Countly.recordEvent(event);
  }

  void eventWithSegment() {
    // example for event with segment
    final event = {'key': 'Event With Segment', 'count': 1};
    event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
    Countly.recordEvent(event);
  }

  void eventWithSumSegment() {
    // example for event with segment and sum
    final event = {
      'key': 'Event With Sum And Segment',
      'count': 1,
      'sum': '0.99',
    };
    event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
    Countly.recordEvent(event);
  }

  void endEventBasic() {
    Countly.startEvent('Timed Event');
    Timer(const Duration(seconds: 5), () {
      Countly.endEvent({'key': 'Timed Event'});
    });
  }

  void endEventWithSum() {
    Countly.startEvent('Timed Event With Sum');
    Timer(const Duration(seconds: 5), () {
      Countly.endEvent({'key': 'Timed Event With Sum', 'sum': '0.99'});
    });
  }

  void endEventWithSegment() {
    Countly.startEvent('Timed Event With Segment');
    Timer(const Duration(seconds: 5), () {
      final event = {
        'key': 'Timed Event With Segment',
        'count': 1,
      };
      event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
      Countly.endEvent(event);
    });
  }

  void endEventWithSumSegment() {
    Countly.startEvent('Timed Event With Segment, Sum and Count');
    Timer(const Duration(seconds: 5), () {
      final event = {
        'key': 'Timed Event With Segment, Sum and Count',
        'count': 1,
        'sum': '0.99'
      };
      event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
      Countly.endEvent(event);
    });
  }

  void recordViewHome() {
    final segments = {'Cats': 123, 'Moons': 9.98, 'Moose': 'Deer'};
    Countly.recordView('HomePage', segments);
  }

  void recordViewDashboard() {
    Countly.recordView('Dashboard');
  }

  void recordDirectAttribution() {
    const campaignData =
        '{cid:"[PROVIDED_CAMPAIGN_ID]", cuid:"[PROVIDED_CAMPAIGN_USER_ID]"}';
    Countly.recordDirectAttribution('countly', campaignData);
  }

  void recordIndirectAttribution() {
    final Map<String, String> attributionValues = {};
    if (Platform.isIOS) {
      attributionValues[AttributionKey.IDFA] = 'IDFA';
    } else {
      attributionValues[AttributionKey.AdvertisingID] = 'AdvertisingID';
    }
    Countly.recordIndirectAttribution(attributionValues);
  }

  String makeid() {
    final code = Random().nextInt(999999);
    final random = code.toString();
    print(random);
    return random;
  }

  void setUserData() {
    final options = {
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

  void _showDialog(String alertText) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert!!'),
          content: Text(alertText),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(navigatorKey.currentContext!).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void getABTestingValues() {
    Countly.remoteConfigUpdate((result) {
      Countly.getRemoteConfigValueForKey('baloon', (result) {
        final alertText = "Value for 'baloon' is : ${result.toString()}";
        _showDialog(alertText);
        print(alertText);
      });
    });
  }

  void eventForGoal_1() {
    final event = {'key': 'eventForGoal_1', 'count': 1};
    Countly.recordEvent(event);
  }

  void eventForGoal_2() {
    final event = {'key': 'eventForGoal_2', 'count': 1};
    Countly.recordEvent(event);
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

  void getDeviceIDType() async {
    final deviceIdType = await Countly.getDeviceIDType();
    if (deviceIdType != null) {
      setState(() {
        _deviceIdType = deviceIdType.toString();
      });
    }
  }

  void changeDeviceIdWithMerge() {
    Countly.changeDeviceId('123456', true);
  }

  void changeDeviceIdWithoutMerge() {
    Countly.changeDeviceId(makeid(), false);
  }

  void addCrashLog() {
    Countly.addCrashLog('User Performed Step A');
    Timer(const Duration(seconds: 5), () {
      Countly.logException(
        'one.js \n two.js \n three.js',
        true,
        {'_facebook_version': '0.0.1'},
      );
    });
  }

  void causeException() {
    final Map<String, Object> options =
        json.decode('This is a deliberate error.');
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
      const firstInput = 20;
      const secondInput = 0;
      final result = firstInput ~/ secondInput;
      print('The result of $firstInput divided by $secondInput is $result');
    } catch (e, s) {
      print('Exception occurs: $e');
      print('STACK TRACE\n: $s');
      Countly.logExceptionEx(e as Exception, true, stacktrace: s);
    }
  }

  void askForStarRating() {
    Countly.askForStarRating();
  }

  void presentRatingWidget() {
    // Trying to show a rating widget with a previously know ID.
    // You should replace the given ID with your own, it would be retrieved
    // from your Countly Dashboard.
    Countly.presentRatingWidgetWithID(
      '61eaaf37c935575c7b932b97',
      closeButtonText: 'close',
      ratingWidgetCallback: (error) {
        if (error != null) {
          print(error);
        }
      },
    );
  }

  void presentRatingWidgetUsingEditBox() {
    // Trying to show a rating widget with the ID give in the App.
    // In the EditBox you would write the ID that you retrieved from your
    // Countly Dashboard.
    Countly.presentRatingWidgetWithID(
      _ratingIdController.text,
      closeButtonText: 'close',
      ratingWidgetCallback: (error) {
        if (error != null) {
          print(error);
        }
      },
    );
  }

  void showFeedbackWidget() async {
    final feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    final widgets = feedbackWidgetsResponse.presentableFeedback;
    final error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    if (widgets.isNotEmpty) {
      await Countly.presentFeedbackWidget(
        widgets.first,
        'Close',
        widgetShown: () {
          print('showFeedbackWidget widget shown');
        },
        widgetClosed: () {
          print('showFeedbackWidget widget closed');
        },
      );
    }
  }

  void showSurvey() async {
    final feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    final widgets = feedbackWidgetsResponse.presentableFeedback;
    final error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (final widget in widgets) {
      if (widget.type == 'survey') {
        await Countly.presentFeedbackWidget(widget, 'Cancel');
        break;
      }
    }
  }

  void showNPS() async {
    final feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    final widgets = feedbackWidgetsResponse.presentableFeedback;
    final error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (final widget in widgets) {
      if (widget.type == 'nps') {
        await Countly.presentFeedbackWidget(widget, 'Close', widgetShown: () {
          print('NPS widget shown');
        }, widgetClosed: () {
          print('NPS widget closed');
        });
        break;
      }
    }
  }

  void reportSurveyManually() async {
    final feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    final widgets = feedbackWidgetsResponse.presentableFeedback;
    final error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }
    for (final widget in widgets) {
      if (widget.type == 'survey') {
        reportSurvey(widget);
        break;
      }
    }
  }

  void reportSurvey(CountlyPresentableFeedback chosenWidget) async {
    final result = await Countly.getFeedbackWidgetData(chosenWidget);
    final error = result[1];
    if (error == null) {
      final Map<String, dynamic>? retrievedWidgetData = result[0];
      final Map<String, Object> segments = {};
      if (retrievedWidgetData != null && retrievedWidgetData.isNotEmpty) {
        final List<dynamic>? questions = retrievedWidgetData['questions'];

        if (questions != null) {
          final rnd = Random();
          //iterate over all questions and set random answers
          for (int a = 0; a < questions.length; a++) {
            final Map<String, dynamic> question = questions[a];
            final String wType = question['type'];
            final String questionId = question['id'];
            final answerKey = 'answ-$questionId';
            switch (wType) {
              //multiple answer question
              case 'multi':
                List<dynamic> choices = question['choices'];
                String str = '';
                for (int b = 0; b < choices.length; b++) {
                  if (b % 2 == 0) {
                    if (b != 0) {
                      str += ',';
                    }
                    // ignore: avoid_dynamic_calls
                    str += choices[b]['key'];
                  }
                }
                segments[answerKey] = str;
                break;
              case 'radio':
              //dropdown value selector
              case 'dropdown':
                final List<dynamic> choices = question['choices'];
                final pick = rnd.nextInt(choices.length);
                // ignore: avoid_dynamic_calls
                segments[answerKey] = choices[pick]['key']; //pick the key of
                // random choice
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
        chosenWidget,
        retrievedWidgetData ?? {},
        segments,
      );
    }
  }

  void reportNPSManually() async {
    final feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    final widgets = feedbackWidgetsResponse.presentableFeedback;
    final error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (final widget in widgets) {
      if (widget.type == 'nps') {
        reportNPS(widget);
        break;
      }
    }
  }

  void reportNPS(CountlyPresentableFeedback chosenWidget) {
    Countly.getFeedbackWidgetData(
      chosenWidget,
      onFinished: (retrievedWidgetData, error) {
        if (error == null) {
          final segments = {'rating': 3, 'comment': 'Filled out comment'};
          Countly.reportFeedbackWidgetManually(
            chosenWidget,
            retrievedWidgetData,
            segments,
          );
        }
      },
    );
  }

  void setLocation() {
    Countly.setUserLocation(
      countryCode: 'TR',
      city: 'Istanbul',
      gpsCoordinates: '41.0082,28.9784',
      ipAddress: '10.2.33.12',
    );
  }

  // APM Examples
  void startTrace() {
    String traceKey = 'Trace Key';
    Countly.startTrace(traceKey);
  }

  void endTrace() {
    const traceKey = 'Trace Key';
    final customMetric = {'ABC': 1233, 'C44C': 1337};
    Countly.endTrace(traceKey, customMetric);
  }

  final successCodes = [100, 101, 200, 201, 202, 205, 300, 301, 303, 305];
  final failureCodes = [400, 402, 405, 408, 500, 501, 502, 505];

  void recordNetworkTraceSuccess() {
    const networkTraceKey = 'api/endpoint.1';
    final rnd = Random();
    final responseCode = successCodes[rnd.nextInt(successCodes.length)];
    final requestPayloadSize = rnd.nextInt(700) + 200;
    final responsePayloadSize = rnd.nextInt(700) + 200;
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final endTime = startTime + 500;
    Countly.recordNetworkTrace(
      networkTraceKey,
      responseCode,
      requestPayloadSize,
      responsePayloadSize,
      startTime,
      endTime,
    );
  }

  void recordNetworkTraceFailure() {
    const networkTraceKey = 'api/endpoint.1';
    final rnd = Random();
    final responseCode = failureCodes[rnd.nextInt(failureCodes.length)];
    final requestPayloadSize = rnd.nextInt(700) + 250;
    final responsePayloadSize = rnd.nextInt(700) + 250;
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final endTime = startTime + 500;
    Countly.recordNetworkTrace(
      networkTraceKey,
      responseCode,
      requestPayloadSize,
      responsePayloadSize,
      startTime,
      endTime,
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _ratingIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messangerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Countly SDK Dart Demo'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text(
                  _deviceIdType,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                MyButton(
                  text: 'Get Device Id Type',
                  color: 'green',
                  onPressed: getDeviceIDType,
                ),
                MyButton(
                  text: 'Begin Session',
                  color: 'green',
                  onPressed: beginSession,
                ),
                MyButton(
                  text: 'Update Session',
                  color: 'green',
                  onPressed: updateSession,
                ),
                MyButton(
                  text: 'End Session',
                  color: 'green',
                  onPressed: endSession,
                ),
                MyButton(
                  text: 'Basic event',
                  color: 'brown',
                  onPressed: basicEvent,
                ),
                MyButton(
                  text: 'Event with Sum',
                  color: 'brown',
                  onPressed: eventWithSum,
                ),
                MyButton(
                  text: 'Event with Segment',
                  color: 'brown',
                  onPressed: eventWithSegment,
                ),
                MyButton(
                  text: 'Even with Sum and Segment',
                  color: 'brown',
                  onPressed: eventWithSumSegment,
                ),
                MyButton(
                  text: 'Timed event: Start / Stop',
                  color: 'grey',
                  onPressed: endEventBasic,
                ),
                MyButton(
                  text: 'Timed event Sum: Start / Stop',
                  color: 'grey',
                  onPressed: endEventWithSum,
                ),
                MyButton(
                  text: 'Timed event Segment: Start / Stop',
                  color: 'grey',
                  onPressed: endEventWithSegment,
                ),
                MyButton(
                  text: 'Timed event Sum Segment: Start / Stop',
                  color: 'grey',
                  onPressed: endEventWithSumSegment,
                ),
                MyButton(
                  text: "Record View: 'HomePage'",
                  color: 'olive',
                  onPressed: recordViewHome,
                ),
                MyButton(
                  text: "Record View: 'Dashboard'",
                  color: 'olive',
                  onPressed: recordViewDashboard,
                ),
                MyButton(
                  text: 'Record Direct Attribution',
                  color: 'olive',
                  onPressed: recordDirectAttribution,
                ),
                MyButton(
                  text: 'Record Indirect Attribution',
                  color: 'olive',
                  onPressed: recordIndirectAttribution,
                ),
                MyButton(
                  text: 'Send Users Data',
                  color: 'teal',
                  onPressed: setUserData,
                ),
                MyButton(
                  text: 'UserData.setProperty',
                  color: 'teal',
                  onPressed: setProperty,
                ),
                MyButton(
                  text: 'UserData.increment',
                  color: 'teal',
                  onPressed: increment,
                ),
                MyButton(
                  text: 'UserData.incrementBy',
                  color: 'teal',
                  onPressed: incrementBy,
                ),
                MyButton(
                  text: 'UserData.multiply',
                  color: 'teal',
                  onPressed: multiply,
                ),
                MyButton(
                  text: 'UserData.saveMax',
                  color: 'teal',
                  onPressed: saveMax,
                ),
                MyButton(
                  text: 'UserData.saveMin',
                  color: 'teal',
                  onPressed: saveMin,
                ),
                MyButton(
                  text: 'UserData.setOnce',
                  color: 'teal',
                  onPressed: setOnce,
                ),
                MyButton(
                  text: 'UserData.pushUniqueValue',
                  color: 'teal',
                  onPressed: pushUniqueValue,
                ),
                MyButton(
                  text: 'UserData.pushValue',
                  color: 'teal',
                  onPressed: pushValue,
                ),
                MyButton(
                  text: 'UserData.pullValue',
                  color: 'teal',
                  onPressed: pullValue,
                ),
                MyButton(
                  text: 'Give multiple consent',
                  color: 'blue',
                  onPressed: giveMultipleConsent,
                ),
                MyButton(
                  text: 'Remove multiple consent',
                  color: 'blue',
                  onPressed: removeMultipleConsent,
                ),
                MyButton(
                  text: 'Give all Consent',
                  color: 'blue',
                  onPressed: giveAllConsent,
                ),
                MyButton(
                  text: 'Remove all Consent',
                  color: 'blue',
                  onPressed: removeAllConsent,
                ),
                MyButton(
                  text: 'Give Consent Sessions',
                  color: 'blue',
                  onPressed: giveConsentSessions,
                ),
                MyButton(
                  text: 'Give Consent Events',
                  color: 'blue',
                  onPressed: giveConsentEvents,
                ),
                MyButton(
                  text: 'Give Consent Views',
                  color: 'blue',
                  onPressed: giveConsentViews,
                ),
                MyButton(
                  text: 'Give Consent Location',
                  color: 'blue',
                  onPressed: giveConsentLocation,
                ),
                MyButton(
                  text: 'Give Consent Crashes',
                  color: 'blue',
                  onPressed: giveConsentCrashes,
                ),
                MyButton(
                  text: 'Give Consent Attribution',
                  color: 'blue',
                  onPressed: giveConsentAttribution,
                ),
                MyButton(
                  text: 'Give Consent Users',
                  color: 'blue',
                  onPressed: giveConsentUsers,
                ),
                MyButton(
                  text: 'Give Consent Push',
                  color: 'blue',
                  onPressed: giveConsentPush,
                ),
                MyButton(
                  text: 'Give Consent starRating',
                  color: 'blue',
                  onPressed: giveConsentStarRating,
                ),
                MyButton(
                  text: 'Give Consent Performance',
                  color: 'blue',
                  onPressed: giveConsentAPM,
                ),
                MyButton(
                  text: 'Remove Consent Sessions',
                  color: 'blue',
                  onPressed: removeConsentsessions,
                ),
                MyButton(
                  text: 'Remove Consent Events',
                  color: 'blue',
                  onPressed: removeConsentEvents,
                ),
                MyButton(
                  text: 'Remove Consent Views',
                  color: 'blue',
                  onPressed: removeConsentViews,
                ),
                MyButton(
                  text: 'Remove Consent Location',
                  color: 'blue',
                  onPressed: removeConsentlocation,
                ),
                MyButton(
                  text: 'Remove Consent Crashes',
                  color: 'blue',
                  onPressed: removeConsentcrashes,
                ),
                MyButton(
                  text: 'Remove Consent Attribution',
                  color: 'blue',
                  onPressed: removeConsentattribution,
                ),
                MyButton(
                  text: 'Remove Consent Users',
                  color: 'blue',
                  onPressed: removeConsentusers,
                ),
                MyButton(
                  text: 'Remove Consent Push',
                  color: 'blue',
                  onPressed: removeConsentpush,
                ),
                MyButton(
                  text: 'Remove Consent starRating',
                  color: 'blue',
                  onPressed: removeConsentstarRating,
                ),
                MyButton(
                  text: 'Remove Consent Performance',
                  color: 'blue',
                  onPressed: removeConsentAPM,
                ),
                const Text(
                  'Section for A/B testing:',
                  style: TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
                MyButton(
                  text: 'Get AB testing values',
                  color: 'green',
                  onPressed: getABTestingValues,
                ),
                MyButton(
                  text: 'Record event for goal #1',
                  color: 'green',
                  onPressed: eventForGoal_1,
                ),
                MyButton(
                  text: 'Record event for goal #2',
                  color: 'green',
                  onPressed: eventForGoal_2,
                ),
                MyButton(
                  text: 'Countly.remoteConfigUpdate',
                  color: 'purple',
                  onPressed: remoteConfigUpdate,
                ),
                MyButton(
                  text: 'Countly.updateRemoteConfigForKeysOnly',
                  color: 'purple',
                  onPressed: updateRemoteConfigForKeysOnly,
                ),
                MyButton(
                  text: 'Countly.updateRemoteConfigExceptKeys',
                  color: 'purple',
                  onPressed: updateRemoteConfigExceptKeys,
                ),
                MyButton(
                  text: 'Countly.remoteConfigClearValues',
                  color: 'purple',
                  onPressed: remoteConfigClearValues,
                ),
                MyButton(
                  text: 'Get String Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyString,
                ),
                MyButton(
                  text: 'Get Boolean Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyBoolean,
                ),
                MyButton(
                  text: 'Get Float Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyFloat,
                ),
                MyButton(
                  text: 'Get Integer Value',
                  color: 'purple',
                  onPressed: getRemoteConfigValueForKeyInteger,
                ),
                MyButton(
                  text: 'Push Notification',
                  color: 'primary',
                  onPressed: askForNotificationPermission,
                ),
                MyButton(
                  text: 'Enable Temporary ID Mode',
                  color: 'violet',
                  onPressed: enableTemporaryIdMode,
                ),
                MyButton(
                  text: 'Change Device ID With Merge',
                  color: 'violet',
                  onPressed: changeDeviceIdWithMerge,
                ),
                MyButton(
                  text: 'Change Device ID Without Merge',
                  color: 'violet',
                  onPressed: changeDeviceIdWithoutMerge,
                ),
                MyButton(
                  text: 'setLocation',
                  color: 'violet',
                  onPressed: setLocation,
                ),
                MyButton(
                  text: 'Send Crash Report',
                  color: 'violet',
                  onPressed: addCrashLog,
                ),
                MyButton(
                  text: 'Cause Exception',
                  color: 'violet',
                  onPressed: causeException,
                ),
                MyButton(
                  text: 'Throw Exception',
                  color: 'violet',
                  onPressed: throwException,
                ),
                MyButton(
                  text: 'Throw Exception Async',
                  color: 'violet',
                  onPressed: throwExceptionAsync,
                ),
                MyButton(
                  text: 'Throw Native Exception',
                  color: 'violet',
                  onPressed: throwNativeException,
                ),
                MyButton(
                  text: 'Record Exception Manually',
                  color: 'violet',
                  onPressed: recordExceptionManually,
                ),
                MyButton(
                  text: 'Divided By Zero Exception',
                  color: 'violet',
                  onPressed: dividedByZero,
                ),
                MyButton(
                  text: 'Open rating modal',
                  color: 'orange',
                  onPressed: askForStarRating,
                ),
                MyButton(
                  text: 'Open feedback modal',
                  color: 'orange',
                  onPressed: presentRatingWidget,
                ),
                TextField(
                  controller: _ratingIdController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a Rating ID',
                  ),
                ),
                MyButton(
                  text: 'Show Rating using EditBox',
                  color: 'orange',
                  onPressed: _ratingIdController.text.isNotEmpty
                      ? presentRatingWidgetUsingEditBox
                      : null,
                ),
                MyButton(
                  text: 'Show Survey',
                  color: 'orange',
                  onPressed: showSurvey,
                ),
                MyButton(
                  text: 'Show NPS',
                  color: 'orange',
                  onPressed: showNPS,
                ),
                MyButton(
                  text: 'Show Feedback Widget',
                  color: 'orange',
                  onPressed: showFeedbackWidget,
                ),
                MyButton(
                  text: 'Report Survey Manually',
                  color: 'orange',
                  onPressed: reportSurveyManually,
                ),
                MyButton(
                  text: 'Report NPS Manually',
                  color: 'orange',
                  onPressed: reportNPSManually,
                ),
                MyButton(
                  text: 'Start Trace',
                  color: 'black',
                  onPressed: startTrace,
                ),
                MyButton(
                  text: 'End Trace',
                  color: 'black',
                  onPressed: endTrace,
                ),
                MyButton(
                  text: 'Record Network Trace Success',
                  color: 'black',
                  onPressed: recordNetworkTraceSuccess,
                ),
                MyButton(
                  text: 'Record Network Trace Failure',
                  color: 'black',
                  onPressed: recordNetworkTraceFailure,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, Map<String, Color>> theColor = {
  'default': {
    'button': const Color(0xffe0e0e0),
    'text': const Color(0xff000000)
  },
  'red': {'button': const Color(0xffdb2828), 'text': const Color(0xff000000)},
  'green': {'button': Colors.green, 'text': const Color(0xffffffff)},
  'teal': {'button': const Color(0xff00b5ad), 'text': const Color(0xff000000)},
  'blue': {'button': const Color(0xff00b5ad), 'text': const Color(0xff000000)},
  'primary': {
    'button': const Color(0xff54c8ff),
    'text': const Color(0xff000000)
  },
  'grey': {'button': const Color(0xff767676), 'text': const Color(0xff000000)},
  'brown': {'button': const Color(0xffa5673f), 'text': const Color(0xff000000)},
  'purple': {
    'button': const Color(0xffa333c8),
    'text': const Color(0xff000000)
  },
  'violet': {
    'button': const Color(0xff6435c9),
    'text': const Color(0xff000000)
  },
  'yellow': {
    'button': const Color(0xfffbbd08),
    'text': const Color(0xffffffff)
  },
  'black': {'button': const Color(0xff1b1c1d), 'text': const Color(0xffffffff)},
  'olive': {'button': const Color(0xffd9e778), 'text': const Color(0xff000000)},
  'orange': {'button': const Color(0xffff851b), 'text': const Color(0xff000000)}
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
  final String? _text;
  late final Color? _button;
  late final Color? _textC;
  final void Function()? _onPressed;

  MyButton({
    required String text,
    String? color,
    void Function()? onPressed,
    Key? key,
  })  : _text = text,
        _onPressed = onPressed,
        super(key: key) {
    final Map<String, Color>? tColor = getColor(color) ?? theColor['default'];
    _button = tColor?['button'];
    _textC = tColor?['text'];
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _button,
        padding: const EdgeInsets.all(10.0),
        minimumSize: const Size(double.infinity, 36),
      ),
      onPressed: _onPressed,
      child: Text(
        _text!,
        style: TextStyle(color: _textC),
        textAlign: TextAlign.center,
      ),
    );
  }
}
