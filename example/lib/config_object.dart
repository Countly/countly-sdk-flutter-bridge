import 'dart:io';
import 'package:countly_flutter_np/countly_flutter.dart';

// This is where we create the CountlyConfig object that we use in the app
// You can change the values here according to your needs
// You do not need to create a class like this, you can create the CountlyConfig object in the main.dart file
// where you initialize the Countly SDK.
// This is just an example of how you can create a class to hold the CountlyConfig object because we used way too many methods here.
class CountlyConfiguration {
  static final String SERVER_URL = 'https://your.server.ly'; // MANDATORY !!
  static final String APP_KEY = 'YOUR_APP_KEY'; // MANDATORY !!

  // These are optional values that you can set for the Countly SDK
  // Below you can see the methods that uses them
  static final Map<String, String> crashSegment = {'Key': 'Value'};
  static final Map<String, String> userProperties = {'customProperty': 'custom Value', 'username': 'USER_NAME', 'email': 'USER_EMAIL'};
  static final String campaignData = '{"cid":"PROVIDED_CAMPAIGN_ID", "cuid":"PROVIDED_CAMPAIGN_USER_ID"}';
  static final Map<String, String> attributionValues = Platform.isIOS ? {AttributionKey.IDFA: 'IDFA'} : {AttributionKey.AdvertisingID: 'AdvertisingID'};
  static final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
    if (error != null) {
      print('RCDownloadCallback, Result:[$rResult], error:[$error]');
      return;
    }
    String downloadedValuesString = '';
    for (final entry in downloadedValues.entries) {
      downloadedValuesString += '||key: ${entry.key}, value: ${entry.value.value}||\n';
    }
    String message = 'Manual Download, Result:[${rResult}, updatedAll:[${fullValueUpdate}], downloadedValues:[\n${downloadedValuesString}]';
    print(message);
  };

  static CountlyConfig getConfig() {
    if (SERVER_URL == 'https://your.server.ly' || APP_KEY == 'YOUR_APP_KEY') {
      print('Please do not use default set of app key and server url');
    }

    return CountlyConfig(SERVER_URL, APP_KEY)..setLoggingEnabled(true) // Enable countly internal debugging logs
    // Currently only logging is enabled for debugging purposes
    // Below you can see most of the methods that you can use to configure the Countly SDK
    // Remote Config related methods
    //------------------------------------------------------------
    //   ..enableRemoteConfigAutomaticTriggers()
    //   ..enableRemoteConfigValueCaching()
    //   ..enrollABOnRCDownload() // This is for specific circumstances only
    //   ..remoteConfigRegisterGlobalCallback(callback) // Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
    //------------------------------------------------------------
    //   ..enableCrashReporting() // Enable crash reporting to report unhandled crashes to Countly
    //   ..setRequiresConsent(true) // Set that consent should be required for features to work.
    //   ..giveAllConsents() // Either use giveAllConsents or setConsentEnabled
    //   ..setConsentEnabled([
    //     CountlyConsent.sessions,
    //     CountlyConsent.events,
    //     CountlyConsent.views,
    //   ]) // for giving specific consent
    // ..setLocation(countryCode: 'KR', city: 'Seoul', gpsCoordinates: '41.0082,28.9784', ipAddress: '10.2.33.12') // Set user  location.
    //   ..setCustomCrashSegment(crashSegment)
    //   ..setUserProperties(userProperties)
    //   ..recordIndirectAttribution(attributionValues)
    //   ..recordDirectAttribution('countly', campaignData)
    //   ..setRecordAppStartTime(true) // (Deprecated) Enable APM features, use apm interface instead
    // APM Configuration (new interface)
    //------------------------------------------------------------
    //   ..apm.enableForegroundBackgroundTracking() // Enable tracking of app foreground/background durations
    //   ..apm.enableAppStartTimeTracking() // Enable tracking of app start time
    //   ..apm.enableManualAppLoadedTrigger() // Enable manual trigger for app loaded (call Countly.appLoadingFinished())
    //   ..apm.setAppStartTimestampOverride(0) // Override the app start timestamp (milliseconds since epoch)
    //------------------------------------------------------------
    // Experimental features
    //------------------------------------------------------------
    //   ..experimental.enableVisibilityTracking() // Enable visibility tracking of the application
    //   ..experimental.enablePreviousNameRecording() // Enable recording previous event/view names
    //------------------------------------------------------------
    // SDK Internal Limits
    //------------------------------------------------------------
    //   ..sdkInternalLimits.setMaxKeyLength(128) // Max character size of all string keys (default 128)
    //   ..sdkInternalLimits.setMaxValueSize(256) // Max character size of all values in key-value pairs (default 256)
    //   ..sdkInternalLimits.setMaxSegmentationValues(100) // Max custom segmentation key-value pairs per event (default 100)
    //   ..sdkInternalLimits.setMaxBreadcrumbCount(100) // Max breadcrumbs before oldest is deleted (default 100)
    //   ..sdkInternalLimits.setMaxStackTraceLinesPerThread(30) // Max stack trace lines per thread (default 30)
    //   ..sdkInternalLimits.setMaxStackTraceLineLength(200) // Max characters per stack trace line (default 200)
    //------------------------------------------------------------
    // Content features
    //------------------------------------------------------------
    //   ..content.setGlobalContentCallback((contentStatus, contentData) {
    //     print('Content callback: status=$contentStatus, data=$contentData');
    //   }) // Set a global callback for content actions
    //   ..content.setZoneTimerInterval(30) // Set interval for automatic content zone refresh in seconds
    //   ..content.setWebviewDisplayOption(WebViewDisplayOption.safeArea) // Set webview display mode (immersive or safeArea)
    //------------------------------------------------------------
    // Device ID configuration
    //   ..setDeviceId('CUSTOM_DEVICE_ID') // Set a custom device ID
    //   ..enableTemporaryDeviceIDMode() // Enable temporary device ID mode
    // Queue and timing configuration
    //   ..setEventQueueSizeToSend(10) // Set event queue threshold before sending (default 10)
    //   ..setUpdateSessionTimerDelay(60) // Set session update interval in seconds (min: 1, max: 600)
    //   ..setMaxRequestQueueSize(1000) // Max requests stored when server is unreachable (default 1000)
    //   ..setRequestDropAgeHours(24) // Drop requests older than given hours
    // SDK behavior configuration
    //   ..disableBackoffMechanism() // Disable the backoff mechanism for request retries
    //   ..disableSDKBehaviorSettingsUpdates() // Disable server config updates
    //   ..disableStoringDefaultPushConsent() // Disable storing default push consent
    //   ..disableViewRestartForManualRecording() // Disable view restart for manual recording
    //   ..setSDKBehaviorSettings('{}') // Provide server config if not available at init time
    //   ..setStarRatingTextMessage('Message for start rating dialog')
    //   ..setParameterTamperingProtectionSalt('salt') // Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request
    //   ..enableManualSessionHandling() // Enable manual session handling
    //   ..setHttpPostForced(true) // Set to 'false' if you want HTTP POST not to be used for all requests
    //   ..setRequestTimeoutDuration(15) // Set the request timeout duration to 15 seconds
    //   ..setCustomNetworkRequestHeaders({
    //           'Content-Type': 'application/json',
    //           'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
    //           'Custom-Header': 'CustomValue'
    //         }) // Set if you want custom HTTP headers to be used for all requests
    //   ..disableLocation() // Call if you want to disable location tracking
    ;
  }
}
