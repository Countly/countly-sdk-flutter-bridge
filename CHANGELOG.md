## 20.11.0
* Added Surveys and NPS feedback widgets
* Added replaceAllAppKeysInQueueWithCurrentAppKey method to replace all app keys in queue with the current app key
* Added removeDifferentAppKeysFromQueue method to remove all different app keys from the queue
* Added setStarRatingDialogTexts method to set text's for different fields of star rating dialog
* Added recordAttributionID method to set the attribution ID for iOS.
* Google play vulnerability issue fixed due to broadcast receiver for android push notification
* Travis CI added.
* Example app updated with single plugin for both IDFA and App tracking permission for iOS.
* Device id NSNull check added for iOS to fix the length on null crash.
* Added sertLocationInit method to set Location before init,potential issues may cause if location is passed after init.
* Added giveConsentInit method to give Consents before init, some features needed consent before init to work properly.
* Improved Loggig by adding common functions to print logs.
* Fixed issues related to location tracking
* Session stop and start safe checks added.
* Updated underlying android SDK to 20.11.0
* Updated underlying ios SDK to 20.11.0

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
