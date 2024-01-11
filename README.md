[![Codacy Badge](https://api.codacy.com/project/badge/Grade/d7c460a23b694051ad08f3bb2e30808c)](https://app.codacy.com/gh/Countly/countly-sdk-flutter-bridge?utm_source=github.com&utm_medium=referral&utm_content=Countly/countly-sdk-flutter-bridge&utm_campaign=Badge_Grade)

# Countly Flutter SDK

This repository contains the Countly Flutter SDK, which can be integrated into mobile Flutter applications. The Countly Flutter SDK is intended to be used with [Countly Lite](https://github.com/Countly/countly-server) or [Countly Enterprise](https://count.ly/product).

## What is Countly?
[Countly](https://count.ly) is a product analytics solution and innovation enabler that helps teams track product performance and customer journey and behavior across [mobile](https://count.ly/mobile-analytics), [web](https://count.ly/web-analytics),
and [desktop](https://count.ly/desktop-analytics) applications. [Ensuring privacy by design](https://count.ly/privacy-by-design), Countly allows you to innovate and enhance your products to provide personalized and customized customer experiences, and meet key business and revenue goals.

Track, measure, and take action - all without leaving Countly.

* **Questions or feature requests?** [Join the Countly Community on Discord](https://discord.gg/countly)
* **Looking for the Countly Server?** [Countly Lite repository](https://github.com/Countly/countly-server)
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
  runZonedGuarded<void>(() {
    runApp(MaterialApp(home: const MyApp()));
  }, Countly.recordDartError);
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

    Countly.isInitialized().then((bool isInitialized) {
      if (!isInitialized) {
        final CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true);
        Countly.initWithConfig(config);
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
final CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)
  ..enableCrashReporting()
Countly.initWithConfig(config);
```

## Reporting Exceptions manually

```dart
Countly.logException('This is a manually created exception', true, null);
```

## Recording Events

```dart
Countly.recordEvent({'key': 'Basic Event', 'count': 1});
```

## Recording Views

```dart
// start recording view
await Countly.instance.views.startView('HomePage');

// stop recording view
await Countly.instance.views.stopViewWithName('HomePage');
```

## Change Device ID

```dart
// with merge
await Countly.changeDeviceId('123456', true);

// without merge
await Countly.changeDeviceId('123456', false);
```

## Get Device ID Type

```dart
final DeviceIdType? deviceIdtype = await Countly.getDeviceIDType();
```

## User Profile

```dart
final Map<String, Object> options = {
  'name': 'Name of User',
  'username': 'Username',
  'email': 'User Email',
  'phone': 'User Contact number',
  'gender': 'User Gender',
};
Countly.instance.userProfile.setUserProperties(options);

// save user profile
Countly.instance.userProfile.save();

// clear user profile
Countly.instance.userProfile.clear();
```

## Consent

```dart
// give multiple consent
Countly.giveConsent(['events', 'views', 'star-rating', 'crashes']);

// remove multiple consent
Countly.removeConsent(['events', 'views', 'star-rating', 'crashes']);

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
If you like Countly, [why not use one of our badges](https://count.ly/brand-assets) and give a link back to us so others know about this wonderful platform?

<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://count.ly/badges/dark.svg?v2" alt="Countly - Product Analytics" /></a>

```JS
<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://count.ly/badges/dark.svg" alt="Countly - Product Analytics" /></a>
```

<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://count.ly/badges/light.svg?v2" alt="Countly - Product Analytics" /></a>

```JS
<a href="https://count.ly/f/badge" rel="nofollow"><img style="width:145px;height:60px" src="https://count.ly/badges/light.svg" alt="Countly - Product Analytics" /></a>
```

## How can I help you with your efforts?
Glad you asked! For community support, feature requests, and engaging with the Countly Community, please join us at [our Discord Server](https://discord.gg/countly). We're excited to have you there!

Also, we are on [Twitter](https://twitter.com/gocountly) and [LinkedIn](https://www.linkedin.com/company/countly) if you would like to keep up with Countly related updates.
