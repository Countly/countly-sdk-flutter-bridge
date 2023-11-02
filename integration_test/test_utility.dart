import 'package:countly_flutter_np/countly_config.dart';

/*
Countly Flutter SDK Test Structure
Test Should grouped according to modules
Each module would have a separate folder under integration_test
In each folder would have a separate file for each test case
Each test case file would have a SINGLE!! test case
Tests should start by initializing the SDK
Then wait for 1 second (or enough)
Then tests should follow accordingly
*/

/*
To run the tests at the root of the project run:
  flutter clean
  flutter pub get
  flutter test integration_test
This would go through each test under the integration_test folder (and sub folders)
*/

// Constants
// ignore: constant_identifier_names
const String SERVER_URL = 'https://xxx.count.ly';
// ignore: constant_identifier_names
const String APP_KEY = 'YOUR_APP_KEY';
// ignore: constant_identifier_names
const String DEVICE_ID = 'DEVICE_ID';

/// Creates a base CountlyConfig object for testing.
CountlyConfig createBaseConfig() {
  CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)
    ..setRequiresConsent(false)
    ..setDeviceId(DEVICE_ID)
    ..setLoggingEnabled(true);
  return config;
}
