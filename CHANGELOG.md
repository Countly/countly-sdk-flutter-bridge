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
* !! Due to cocoapods issue with Xcode 12, we have added the iOS SDK as source code instead of Pod. Due to that change if you have already added the reference of files "CountlyNotificationService.h/m" then you need to update these files references by adding the files from "Pods/Development Pods/countly_flutter" and remove the old reference files
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
