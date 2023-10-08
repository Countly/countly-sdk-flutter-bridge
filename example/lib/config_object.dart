import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';

// This is where we create the CountlyConfig object that we use in the app
// You can change the values here according to your needs
// You do not need to create a class like this, you can create the CountlyConfig object in the main.dart file
// where you initialize the Countly SDK.
// This is just an example of how you can create a class to hold the CountlyConfig object because we used way too many methods here.
class CountlyConfiguration {
  static final String SERVER_URL = 'https://xxx.count.ly'; // MANDATORY !!
  static final String APP_KEY = 'YOUR_APP_KEY'; // MANDATORY !!
  static final Map<String, String> crashSegment = {'Key': 'Value'};
  static final Map<String, String> userProperties = {'customProperty': 'custom Value', 'username': 'USER_NAME', 'email': 'USER_EMAIL'};
  static final String campaignData = '{"cid":"PROVIDED_CAMPAIGN_ID", "cuid":"PROVIDED_CAMPAIGN_USER_ID"}';
  static final Map<String, String> attributionValues = Platform.isIOS ? {AttributionKey.IDFA: 'IDFA'} : {AttributionKey.AdvertisingID: 'AdvertisingID'};

  static CountlyConfig getConfig() {
    return CountlyConfig(SERVER_URL, APP_KEY)
      ..enableCrashReporting() // Enable crash reporting to report unhandled crashes to Countly
      ..setRequiresConsent(true) // Set that consent should be required for features to work.
      ..giveAllConsents() // Either use giveAllConsents or setConsentEnabled
      //   ..setConsentEnabled([
      //     CountlyConsent.sessions,
      //     CountlyConsent.events,
      //     CountlyConsent.views,
      //   ]) // for giving specific consent
      ..setLocation(country_code: 'KR', city: 'Seoul', ipAddress: '41.0082,28.9784', gpsCoordinates: '10.2.33.12') // Set user  location.
      ..setCustomCrashSegment(crashSegment)
      ..setUserProperties(userProperties)
      ..recordIndirectAttribution(attributionValues)
      ..recordDirectAttribution('countly', campaignData)
      ..remoteConfigRegisterGlobalCallback((rResult, error, fullValueUpdate, downloadedValues) {
        print('Global RC download callback 1');
        if (error != null) {
          print(error);
        }
      }) // Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
      ..remoteConfigRegisterGlobalCallback((rResult, error, fullValueUpdate, downloadedValues) {
        print('Global RC download callback 2');
        if (error != null) {
          print(error);
        }
      }) // Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
      ..setRecordAppStartTime(true) // Enable APM features, which includes the recording of app start time.
      ..setStarRatingTextMessage('Message for start rating dialog')
      ..setLoggingEnabled(true) // Enable countly internal debugging logs
      //..enrollABOnRCDownload() // This is for specific circumstances only
      ..setParameterTamperingProtectionSalt('salt') // Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request
      //..enableManualSessionHandling() // Enable manual session handling
      ..setHttpPostForced(false); // Set to 'true' if you want HTTP POST to be used for all requests
  }
}
