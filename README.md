[![Codacy Badge](https://app.codacy.com/project/badge/Grade/7ab95afb3da8421ab499cc921e1381ac)](https://app.codacy.com/gh/Countly/countly-sdk-flutter-bridge/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# Countly Flutter SDK

This repository contains the Countly Flutter SDK, which can be integrated into mobile Flutter applications. The Countly Flutter SDK is intended to be used with [Countly Lite](https://countly.com/lite), [Countly Flex](https://countly.com/flex), [Countly Enterprise](https://countly.com/enterprise).

## What is Countly?
[Countly](https://countly.com) is a product analytics solution and innovation enabler that helps teams track product performance and customer journey and behavior across [mobile](https://countly.com/mobile-analytics), [web](https://countly.com/web-analytics),
and [desktop](https://countly.com/desktop-analytics) applications. [Ensuring privacy by design](https://countly.com/privacy-by-design), Countly allows you to innovate and enhance your products to provide personalized and customized customer experiences, and meet key business and revenue goals.

Track, measure, and take action - all without leaving Countly.

* **Questions or feature requests?** [Join the Countly Community on Discord](https://discord.gg/countly)
* **Looking for the Countly Server?** [Countly Server repository](https://github.com/Countly/countly-server)
* **Looking for other Countly SDKs?** [An overview of all Countly SDKs for mobile, web and desktop](https://support.count.ly/hc/en-us/articles/360037236571-Downloading-and-Installing-SDKs#h_01H9QCP8G5Y9PZJGERZ4XWYDY9)

## Integrating Countly SDK in your projects

For a detailed description on how to use this SDK [check out our documentation](https://support.count.ly/hc/en-us/articles/360037944212-Flutter).

For information about how to add the SDK to your project, please check [this section of the documentation](https://support.count.ly/hc/en-us/articles/360037944212-Flutter#h_01H930GAQ59MD94NK0NP68GNGT).

You can find minimal SDK integration information for your project in [this section of the documentation](https://support.count.ly/hc/en-us/articles/360037944212-Flutter#h_01H930GAQ5RGKSA3CTNVTBTDZF).

For an example integration of this SDK, you can have a look [here](https://github.com/Countly/countly-sdk-flutter-bridge/tree/master/example).

This SDK supports the following features:
* [Analytics](https://support.count.ly/hc/en-us/articles/4431589003545-Analytics)
* [Push Notifications](https://support.count.ly/hc/en-us/articles/4405405459225-Push-Notifications)
* [User Profiles](https://support.count.ly/hc/en-us/articles/4403281285913-User-Profiles)
* [Crash Reports](https://support.count.ly/hc/en-us/articles/4404213566105-Crashes-Errors)
* [A/B Testing](https://support.count.ly/hc/en-us/articles/4416496362393-A-B-Testing-)
* [Performance Monitoring](https://support.count.ly/hc/en-us/articles/4734457847705-Performance)
* [Feedback Widgets](https://support.count.ly/hc/en-us/articles/4652903481753-Feedback-Surveys-NPS-and-Ratings-)

## Installation

In the `dependencies:` section of your `pubspec.yaml`, add the following line:

```yaml
dependencies:
  countly_flutter: <latest_version>
```

## Usage

```dart
import 'package:countly_flutter/countly_flutter.dart';

void main() {
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Initialize the SDK once
    Countly.isInitialized().then((bool isInitialized) {
      if (!isInitialized) {
        // Create the configuration with your app key and server URL
        final CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true);
        // In this example, we have logging enabled. For production, disable this.

        // Initialize with that configuration
        Countly.initWithConfig(config).then((value) {
            Countly.start(); // Enables automatic view tracking
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Countly Example App')),
      body: Center(
        child: TextButton(
          onPressed: () {
            // record an event
            Countly.recordEvent({'key': 'Basic Event', 'count': 1});
          },
          child: Text('Record Event'),
        ),
      ),
    );
  }
}
```

## Enabling Automatic Crash Handling

```dart
// This will automatically catch all errors that are thrown from within the Flutter framework.
final CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)
  ..enableCrashReporting()
Countly.initWithConfig(config);
```

## Reporting Exceptions manually

```dart
// Manually report a handled or unhandled exception/error to Countly
Countly.logException('This is a manually created exception', true, null);
```

## Recording Events

```dart
// Record events (User interactions)

final event = {'key': 'Basic Event', 'count': 1};
Countly.recordEvent({'key': 'Basic Event', 'count': 1});

// you can also record events with segmentation
event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
Countly.recordEvent({'key': 'Basic Event', 'count': 1});
```

## Recording Views

```dart
// Record screen views

final segmentation = {'Country': 'Turkey', 'Age': '28'};

// start recording view with segmentation. NB: Segmentation values are optional.
final String? id = await Countly.instance.views.startView('HomePage', segmentation);

// stop recording view with name with segmentation
await Countly.instance.views.stopViewWithName('HomePage', segmentation);

// stop recording view with ID with segmentation
await Countly.instance.views.stopViewWithID(id, segmentation);

// stop recording all views with segmentation
await Countly.instance.views.stopAllViews(segmentation);
```

## Change Device ID

```dart
// A device ID is a unique identifier for your users/device.

// Change device ID with merge.
// Here, the data associated with the previous device ID is merged with the new ID.
await Countly.changeDeviceId('123456', true);

// Change device ID without merge.
// Here, the new device ID is counted as a new device.
await Countly.changeDeviceId('123456', false);
```

## Get Device ID Type

```dart
// To fetch the device ID type
final DeviceIdType? deviceIdtype = await Countly.getDeviceIDType();
// DeviceIdType: DEVELOPER_SUPPLIED, SDK_GENERATED, TEMPORARY_ID
```

## User Profile

```dart
// To provide information regarding the current user, use this.

final Map<String, Object> options = {
  'name': 'Name of User',
  'username': 'Username',
  'email': 'User Email',
  'phone': 'User Contact number',
  'gender': 'User Gender',
};
Countly.instance.userProfile.setUserProperties(options);

// Increment custom property value by 1
Countly.instance.userProfile.increment('increment');

// Increment custom property value by 10
Countly.instance.userProfile.incrementBy('incrementBy', 10);

// Multiply custom property value by 20
Countly.instance.userProfile.multiply('multiply', 20);

// Save max value between current value and provided value
Countly.instance.userProfile.saveMax('saveMax', 100);

// Save min value between current value and provided value
Countly.instance.userProfile.saveMin('saveMin', 50);

// Set custom property value if it doesn't exist
Countly.instance.userProfile.setOnce('setOnce', '200');

// Add unique value to custom property array
Countly.instance.userProfile.pushUnique('pushUniqueValue', 'morning');

// Add unique value to custom property array if it does not exist
Countly.instance.userProfile.push('pushValue', 'morning');

// Remove value from custom property array
Countly.instance.userProfile.pull('pushValue', 'morning');

// Send/Save provided values to server. After setting values, you must save it by calling save();
Countly.instance.userProfile.save();

// Clear queued operations / modifications
Countly.instance.userProfile.clear();
```

## Consent

```dart
// For compatibility with data protection regulations, such as GDPR, the Countly
// Flutter SDK allows developers to enable/disable any feature at any time depending
// on user consent.

// Consent values: sessions, events, views, location, crashes, attribution, users, push, starRating, apm, feedback, remoteConfig

// Consent can be enabled during initialization
final CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)
  ..setConsentEnabled([CountlyConsent.sessions]);
Countly.initWithConfig(config);

// Or after initialization using one of the below methods
// give multiple consent
Countly.giveConsent([CountlyConsent.events, CountlyConsent.views, CountlyConsent.crashes]);

// remove multiple consent
Countly.removeConsent([CountlyConsent.events, CountlyConsent.views, CountlyConsent.crashes]);

// give all consent
Countly.giveAllConsent();

// remove all consent
Countly.removeAllConsent();
```

## Acknowledgements

From 2014 to 2020 it was maintained by Trinisoft Technologies developers (trinisofttechnologies@gmail.com).

## Security
Security is very important to us. If you discover any issue regarding security, please disclose the information responsibly by sending an email to security@count.ly and **not by creating a GitHub issue**.

## Badges
If you like Countly, [why not use one of our badges](https://countly.com/brand-assets) and give a link back to us so others know about this wonderful platform?

<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://countly.com/badges/dark.svg?v2" alt="Countly - Product Analytics" /></a>

```JS
<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://countly.com/badges/dark.svg" alt="Countly - Product Analytics" /></a>
```

<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://countly.com/badges/light.svg?v2" alt="Countly - Product Analytics" /></a>

```JS
<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://countly.com/badges/light.svg" alt="Countly - Product Analytics" /></a>
```

## How can I help you with your efforts?
Glad you asked! For community support, feature requests, and engaging with the Countly Community, please join us at [our Discord Server](https://discord.gg/countly). We're excited to have you there!

Also, we are on [Twitter](https://twitter.com/gocountly) and [LinkedIn](https://www.linkedin.com/company/countly) if you would like to keep up with Countly related updates.
