import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/config_object.dart';

import 'package:countly_flutter_example/helpers.dart';
import 'package:countly_flutter_example/page_apm.dart';
import 'package:countly_flutter_example/page_consent.dart';
import 'package:countly_flutter_example/page_crash_reporting.dart';
import 'package:countly_flutter_example/page_device_id.dart';
import 'package:countly_flutter_example/page_events.dart';
import 'package:countly_flutter_example/page_feedback_widgets.dart';
import 'package:countly_flutter_example/page_content.dart';
import 'package:countly_flutter_example/page_others.dart';
import 'package:countly_flutter_example/page_remote_config.dart';
import 'package:countly_flutter_example/page_sessions.dart';
import 'package:countly_flutter_example/page_user_profiles.dart';
import 'package:countly_flutter_example/page_views.dart';
import 'package:countly_flutter_example/style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: AppTheme.countlyTheme(),
      debugShowCheckedModeBanner: false,
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      Countly.pushTokenType(Countly.messagingMode['TEST']!); // Set messaging mode for push notifications
    }

    CountlyConfig config = CountlyConfiguration.getConfig();
    Countly.initWithConfig(config).then((value) {
      Countly.appLoadingFinished(); // for APM feature

      if (!kIsWeb) {
        /// Push notifications settings. Should be call after init
        Countly.onNotification((String notification) {
          print('The notification:[$notification]');
        }); // Set callback to receive push notifications

        Countly.askForNotificationPermission(); // This method will ask for permission, enables push notification and send push token to countly server.;
      }

      Countly.instance.remoteConfig.registerDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {
        print('download callback after init 3');
      });
    }); // Initialize the countly SDK.
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final navItems = <_NavItem>[
      _NavItem(icon: Icons.play_circle_outline, title: 'Sessions', subtitle: 'Manual session management', page: SessionsPage()),
      _NavItem(icon: Icons.event_note, title: 'Events', subtitle: 'Record and time events', page: EventsPage()),
      _NavItem(icon: Icons.visibility, title: 'Views', subtitle: 'Track screen views', page: ViewsPage()),
      _NavItem(icon: Icons.devices, title: 'Device ID Management', subtitle: 'Device identification and merging', page: DeviceIDPage()),
      _NavItem(icon: Icons.web_outlined, title: 'Content', subtitle: 'Content zones and device ID', page: ContentPage()),
      _NavItem(icon: Icons.person, title: 'User Profiles', subtitle: 'User data and custom properties', page: UserProfilesPage()),
      _NavItem(icon: Icons.privacy_tip_outlined, title: 'Consent', subtitle: 'Feature consent management', page: ConsentPage()),
      _NavItem(icon: Icons.feedback_outlined, title: 'Feedback Widgets', subtitle: 'NPS, surveys, and ratings', page: FeedbackWidgetsPage()),
      _NavItem(icon: Icons.cloud_sync_outlined, title: 'Remote Config', subtitle: 'Remote configuration and A/B testing', page: RemoteConfigPage()),
      _NavItem(icon: Icons.speed, title: 'APM', subtitle: 'Application performance monitoring', page: APMPage()),
      _NavItem(icon: Icons.bug_report_outlined, title: 'Crash Reporting', subtitle: 'Exception and crash reporting', page: CrashReportingPage()),
      _NavItem(icon: Icons.more_horiz, title: 'Other Features', subtitle: 'Location, attribution, misc', page: OthersPage()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/banner.png', height: 32),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: navItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = navItems[index];
          return Card(
            child: ListTile(
              leading: Icon(item.icon, color: colorScheme.primary),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => navigateToPage(context, item.page),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });
}
