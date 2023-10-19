import 'dart:async';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/config_object.dart';

import 'package:countly_flutter_example/helpers.dart';
import 'package:countly_flutter_example/page_apm.dart';
import 'package:countly_flutter_example/page_consent.dart';
import 'package:countly_flutter_example/page_crash_reporting.dart';
import 'package:countly_flutter_example/page_device_id.dart';
import 'package:countly_flutter_example/page_events.dart';
import 'package:countly_flutter_example/page_feedback_widgets.dart';
import 'package:countly_flutter_example/page_others.dart';
import 'package:countly_flutter_example/page_remote_config.dart';
import 'package:countly_flutter_example/page_sessions.dart';
import 'package:countly_flutter_example/page_user_profiles.dart';
import 'package:countly_flutter_example/page_views.dart';
import 'package:countly_flutter_example/style.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// This or a similar call needs to added to catch and report Dart Errors to Countly,
/// You need to run the app inside a Zone
/// and provide the [Countly.recordDartError] callback for [onError()]
void main() {
  runZonedGuarded<Future<void>>(() async {
    runApp(
      MaterialApp(
        theme: AppTheme.countlyTheme(),
        debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    Countly.isInitialized().then((bool isInitialized) {
      if (!isInitialized) {
        Countly.pushTokenType(Countly.messagingMode['TEST']!); // Set messaging mode for push notifications

        CountlyConfig config = CountlyConfiguration.getConfig();
        Countly.initWithConfig(config).then((value) {
          Countly.appLoadingFinished(); // for APM feature

          /// Push notifications settings. Should be call after init
          Countly.onNotification((String notification) {
            print('The notification:[$notification]');
          }); // Set callback to receive push notifications

          Countly.askForNotificationPermission(); // This method will ask for permission, enables push notification and send push token to countly server.;

          Countly.instance.remoteConfig.registerDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {
            print('download callback after init 3');
          });
        }); // Initialize the countly SDK.
      } else {
        print('Countly: Already initialized!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messangerKey,
      theme: AppTheme.countlyTheme(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          flexibleSpace: Image(
            image: AssetImage("assets/banner.png"),
            fit: BoxFit.cover,
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
            child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: <Widget>[
              MyButton(
                  text: 'Sessions',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, SessionsPage());
                  }),
              MyButton(
                  text: 'Events',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, EventsPage());
                  }),
              MyButton(
                  text: 'Views',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, ViewsPage());
                  }),
              MyButton(
                  text: 'Device ID Management',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, DeviceIDPage());
                  }),
              MyButton(
                  text: 'User Profiles',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, UserProfilesPage());
                  }),
              MyButton(
                  text: 'Consent',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, ConsentPage());
                  }),
              MyButton(
                  text: 'Feedback Widgets',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, FeedbackWidgetsPage());
                  }),
              MyButton(
                  text: 'Remote Config',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, RemoteConfigPage());
                  }),
              MyButton(
                  text: 'APM',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, APMPage());
                  }),
              MyButton(
                  text: 'Crash Reporting',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, CrashReportingPage());
                  }),
              MyButton(
                  text: 'Other Features',
                  color: 'green',
                  onPressed: () {
                    navigateToPage(context, OthersPage());
                  }),
            ],
          ),
        )),
      ),
    );
  }
}
