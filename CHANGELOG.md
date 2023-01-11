## 22.09.0
* Fixed isInitialized variable reset on hot reload.
* Underlying android SDK version is 22.06.2
* Underlying iOS SDK version is 22.09.0

## 22.02.1
* SDK has been internally slightly reworked to support a "no push notification" variant.
* Fixed incorrect iOS push token type when passing "Countly.messagingMode.PRODUCTION" as token type.
* Underlying android SDK version is 22.02.1
* Underlying iOS SDK version is 22.06.0

## 22.02.1-np
* This flavor is a "no push notification" variant of the Countly SDK.
* Underlying android SDK version is 22.02.1
* Underlying iOS SDK version is 22.06.0

## 22.02.0
* Fixed notification trampoline restrictions in Android 12 using reverse activity trampolining implementation.
* Adding a call to provide user properties during initialization.
* Updated underlying android SDK version to 22.02.1
* Updated underlying iOS SDK version to 22.06.0

## 21.11.2
* Making logs more verbose on iOS by printing network related logs.
* Underlying android SDK is 21.11.2
* Underlying iOS SDK version is 21.11.2

## 21.11.1
* Fixed bug that caused crashes when migrating from older versions on Android devices.
* Updated underlying android SDK to 21.11.2
* Underlying iOS SDK version is 21.11.2

## 21.11.0
* !! Major breaking change !! Changing device ID without merging will now clear all consent. It has to be given again after this operation.
* !! Major breaking change !! Entering temporary ID mode will now clear all consent. It has to be given again after this operation.
* Added mitigations for potential push notification issue where some apps might be unable to display push notifications in their kill state.
* Added 'CountlyConfig' class for init time configurations.
* Added a way to retrieve feedback widget data and manually report them for iOS also
* Added Appear and dismiss callback for nps/survey widgets
* Added an optional 'onFinished' callback to 'getFeedbackWidgetData' method
* Added "getDeviceIDType" method to get current device id type
* Added "recordIndirectAttribution" method
* Added "recordDirectAttribution" method
* Added "setUserLocation" method to set user location
* Added platform information to push actioned events
* Fixed potential deadlock issue in Android.
* Fixed possible SecTrustCopyExceptions leak in iOS
* Fixed bug that occured when recording user profile values. Parameters not provided would be deleted from the server.
* Deprecated old init config methods. You should use the config object now. Those methods are:
  * init
  * manualSessionHandling
  * updateSessionPeriod
  * updateSessionInterval
  * eventSendThreshold
  * storedRequestsLimit
  * setOptionalParametersForInitialization
  * setLoggingEnabled
  * enableParameterTamperingProtection
  * setHttpPostForced
  * setLocationInit
  * setRequiresConsent
  * giveConsentInit
  * setRemoteConfigAutomaticDownload
  * setStarRatingDialogTexts
  * enableCrashReporting
  * setCustomCrashSegment
  * enableApm
* Deprecated "setLocation" method
* Deprecated recordAttributionID method
* Deprecated enableAttribution method
* Deprecated 'askForFeedback' method. Added 'presentRatingWidgetWithID' method that should be used as it's replacement.
* Device ID can now be changed when no consent is given
* Push notification now display/use the sent badge number in Android. It's visualization depends on the launcher.
* When recording internal events with 'recordEvent', the respective feature consent will now be checked instead of the 'events' consent.
* Consent changes will now send the whole consent state and not just the "delta"
* Updated minimum supported iOS versions to 10.0
* Updated underlying android SDK to 21.11.0
* Updated underlying iOS SDK to 21.11.2

## 20.11.4
* Moving a push related broadcast receiver declaration to the manifest to comply with 'PendingIntent' checks
* Updated underlying android SDK to 20.11.9
* Underlying iOS SDK version is 20.11.1

## 20.11.3
* Migrated to null safety.
* Updated Flutter SDK constraint to >= 2.0.0.
* Updated lower bound of dart dependency to 2.12.0.
* Lint suggestion are added in flutter for better code quality.
* Updated underlying android SDK to 20.11.8
* Underlying iOS SDK version is 20.11.1

## 20.11.2
* Added COUNTLY_EXCLUDE_PUSHNOTIFICATIONS flag to disable push notifications altogether in order to avoid App Store Connect warnings.
* Add "updateSessionInterval" method to sets the interval for the automatic session update calls
* flutter_plugin_android_lifecycle updated to latest version (2.0.1)
* Updated the minimum flutter environment version to 1.10.0
* Updated underlying android SDK to 20.11.8
* Underlying iOS SDK version is 20.11.1

## 20.11.1
* Added a way to retrieve feedback widget data and manually report them
* Updated underlying android SDK to 20.11.4

## 20.11.0
* !! Due to cocoapods issue with Xcode 12, we have added the iOS SDK as source code instead of Pod. Due to that change,
 if you have already added the reference of files "CountlyNotificationService.h/m" then you need to update these files references by adding the files from "Pods/Development Pods/countly_flutter" and remove the old reference files
* !! Consent change !! To use remote config, you now need to give "remote-config" consent
* !! Push breaking changes !! Google play vulnerability issue fixed due to broadcast receiver for android push notification
* Added Surveys and NPS feedback widgets
* Added "replaceAllAppKeysInQueueWithCurrentAppKey" method to replace all app keys in a queue with the current app key
* Added "removeDifferentAppKeysFromQueue" method to remove all different app keys from the queue
* Added "disablePushNotifications" method to disable push notifications for iOS
* Added "setStarRatingDialogTexts" method to set text's for different fields of star rating dialog
* Added "recordAttributionID" method to set the attribution ID for iOS
* Example app updated
* Device id NSNull check added for iOS to fix the length on null crash
* Added "setLocationInit" method to record Location before init, to prevent potential issues occurred when a location is passed after init
* Added "giveConsentInit" method to give Consents before init, some features needed consent before init to work properly
* Fixed issues related to location tracking
* Session stop and start safety checks added
* Fixed issues related to sessions
* Updated underlying android SDK to 20.11.3
* Updated underlying ios SDK to 20.11.1

## 20.04.1
* Adding APM calls
* Improved unhandled crash catching
* Added "isInitialised" call
* Adding functionality to enable attribution
* Adding push notification callbacks
* Improved handling of push notifications when the application was soft killed
* Reworked the android side to support the new Android plugins APIs (V2)
* Fixed a few issues related to location tracking
* Fixed issues with android session handling
* Improved internal error/issue handling
* Improved internal logging
* fixed SDK version and SDK name metrics to show not the bridged SDK values but the ones from the flutter SDK
* Updated underlying android SDK to 20.04.5
* Updated underlying ios SDK to 20.04.2

## 20.04.0
* Updating bridged ios and android Countly SDK versions
* Added uncaught crash handler for flutter
* Added temporary device ID
* Fixed event duration bug with ios
* Fixed issue with default user profile values

## 19.03.0

* Please refer to this documentation for released work https://support.count.ly/hc/en-us/articles/360037944212-Flutter
