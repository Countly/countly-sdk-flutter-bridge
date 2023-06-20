## 23.6.0
* Reworked the entire remote config feature.
* Converted Countly class to a Singleton.
* Created remote config object and added the following methods:
  * notifyDownloadCallbacks
  * notifyVariantCallbacks
  * clearAll
  * downloadOmittingKeys
  * downloadSpecificKeys
  * downloadAllKeys
  * enrollIntoABTestsForKeys
  * exitABTestsForKeys
  * getAllValues
  * getValue
  * registerDownloadCallback
  * removeDownloadCallback
  * testingDownloadVariantInformation
  * testingEnrollIntoVariant
  * testingGetAllVariants
  * testingGetVariantsForKey

* Introduced a new user profile ('userProfile') interface on the SDK instance that supports bulk operations.

* Deprecated old remote config methods. You should use the remote config object. Deprecated methods are:
  * getABTestingValues
  * remoteConfigUpdate
  * updateRemoteConfigForKeysOnly
  * getRemoteConfigValueForKey
  * updateRemoteConfigExceptKeys
  * remoteConfigClearValues
  * getRemoteConfigValueForKey

* Deprecated old user profile methods. You should use the new user profile interface. Deprecated methods are:
  * 'setUserData'
  * 'setProperty'
  * 'increment'
  * 'incrementBy'
  * 'multiply'
  * 'saveMax'
  * 'saveMin'
  * 'setOnce'
  * 'pushUniqueValue'
  * 'pushValue'
  * 'pullValue'

* Fixed a bug where the app would crash if `gpsCoordinate` in location was null.
* Updated Underlying android SDK version to 23.2.0
* Updated Underlying iOS SDK version to 23.6.0

## 23.6.0-np
* Reworked the entire remote config feature.
* Converted Countly class to a Singleton.
* Created remote config object and added the following methods:
  * notifyDownloadCallbacks
  * notifyVariantCallbacks
  * clearAll
  * downloadOmittingKeys
  * downloadSpecificKeys
  * downloadAllKeys
  * enrollIntoABTestsForKeys
  * exitABTestsForKeys
  * getAllValues
  * getValue
  * registerDownloadCallback
  * removeDownloadCallback
  * testingDownloadVariantInformation
  * testingEnrollIntoVariant
  * testingGetAllVariants
  * testingGetVariantsForKey

* Introduced a new user profile ('userProfile') interface on the SDK instance that supports bulk operations.

* Deprecated old remote config methods. You should use the remote config object. Deprecated methods are:
  * getABTestingValues
  * remoteConfigUpdate
  * updateRemoteConfigForKeysOnly
  * getRemoteConfigValueForKey
  * updateRemoteConfigExceptKeys
  * remoteConfigClearValues
  * getRemoteConfigValueForKey

* Deprecated old user profile methods. You should use the new user profile interface. Deprecated methods are:
  * 'setUserData'
  * 'setProperty'
  * 'increment'
  * 'incrementBy'
  * 'multiply'
  * 'saveMax'
  * 'saveMin'
  * 'setOnce'
  * 'pushUniqueValue'
  * 'pushValue'
  * 'pullValue'

* Fixed a bug where the app would crash if `gpsCoordinate` in location was null.
* Updated Underlying android SDK version to 23.2.0
* Updated Underlying iOS SDK version to 23.6.0

## 23.2.3
* Not reporting battery level in the crash handler to prevent hanging in iOS
* Fixing bug that prevented device ID to be changed when there is no consent given in Android
* Updated Underlying android SDK version to 22.09.4
* Updated Underlying iOS SDK version to 23.02.2

## 23.2.3-np
* Not reporting battery level in the crash handler to prevent hanging in iOS
* Fixing bug that prevented device ID to be changed when there is no consent given in Android
* Updated Underlying android SDK version to 22.09.4
* Updated Underlying iOS SDK version to 23.02.2

## 23.2.2
* Added "previous event ID" logic for non-internal events
* Session update interval upper limit (10 minutes) has been lifted in Android
* Updated default maxSegmentationValues from 30 to 100 for iOS
* Updated Underlying android SDK version to 22.09.3
* Updated Underlying iOS SDK version to 23.02.1

## 23.2.2-np
* Added "previous event ID" logic for non-internal events
* Session update interval upper limit (10 minutes) has been lifted in Android
* Updated default maxSegmentationValues from 30 to 100 for iOS
* Updated Underlying android SDK version to 22.09.3
* Updated Underlying iOS SDK version to 23.02.1

## 23.2.1
* Fixed a bug in Android where metric override values were not applying to crash metrics Fixed a bug where crash metrics sent the "manufacturer" value under the wrong key
* Fixed a bug in Android where orientation events would have the same view ID as the previous view event
* Fixed a bug in Android where view ID's were being reported incorrectly
* Updated Underlying android SDK version to 22.09.1
* Underlying iOS SDK version is 23.02.0

## 23.2.1-np
* Fixed a bug in Android where metric override values were not applying to crash metrics Fixed a bug where crash metrics sent the "manufacturer" value under the wrong key
* Fixed a bug in Android where orientation events would have the same view ID as the previous view event
* Fixed a bug in Android where view ID's were being reported incorrectly
* Updated Underlying android SDK version to 22.09.1
* Underlying iOS SDK version is 23.02.0

## 23.2.0
* !! Major breaking change !! Resolved issue with handling push notification actions on iOS. 
  * To handle push notification actions, add the following call "CountlyFlutterPlugin.startObservingNotifications();" to "AppDelegate.swift"
  * For further information, refer to the "Handling Push Callbacks" section of the Countly SDK documentation at:
    https://support.count.ly/hc/en-us/articles/360037944212-Flutter#handling-push-callbacks.
* Fixed a race condition bug in Android where a recorded event would have the wrong user properties in the drill database on the server. Now event queue is emptied (formed into a request) before recording any user profile changes.
* Events are now recorded with an internal ID in Android.
* Updated Underlying android SDK version to 22.09.0
* Updated Underlying iOS SDK version to 23.02.0

## 23.2.0-np
* Fixed a race condition bug in Android where a recorded event would have the wrong user properties in the drill database on the server. Now event queue is emptied (formed into a request) before recording any user profile changes.
* Events are now recorded with an internal ID in Android.
* Updated Underlying android SDK version to 22.09.0
* Updated Underlying iOS SDK version to 23.02.0

## 22.09.0
* Fixed "isInitialized" variable reset on hot reload.
* Updated underlying android SDK version to 22.06.2
* Updated underlying iOS SDK version to 22.09.0

## 22.09.0-np
* Fixed "isInitialized" variable reset on hot reload.
* Updated underlying android SDK version is 22.06.2
* Updated underlying iOS SDK version is 22.09.0

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
