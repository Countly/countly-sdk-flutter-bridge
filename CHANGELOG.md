## XX.XX.XX

* Added `changeServerUrl(serverUrl)` to the SDK instance to change the server URL after init
* Added `changeAppKey(appKey)` to the SDK instance to change the app key after init
* Added `flushQueues()` to the SDK instance to clear the event and request queues
* Added `replaceAllAppKeysInQueueWithCurrentAppKey()` to the SDK instance to set the current app key on all queued requests
* Added `removeDifferentAppKeysFromQueue()` to the SDK instance to remove queued requests of other app keys

* Underlying Dart SDK version is XX.XX.XX

## 26.1.0

* Initial SDK release with the following functionalities:

* Initialization:
  * `Countly.init(config)` - Initialize the SDK with configuration
  * `Countly.defaultInstance` - Access the default SDK instance
  * `Countly.instance(key)` - Access a specific SDK instance by key
  * `Countly.disposeInstance(key)` - Dispose a specific SDK instance
  * `Countly.disposeAll()` - Dispose all SDK instances
  * Multi-instance support with unique instance keys

* Configuration Options (CountlyConfig)
  * `appKey` (required) - Application key
  * `serverUrl` (required) - Server URL (http:// or https://)
  * `deviceId` - Custom device ID (auto-generated if not provided)
  * `userProperties` - Initial user properties to set
  * `storageMode` - Storage mode (persistent or memory)
  * `storageMethods` - Custom storage implementation
  * `startWithUnknownConsent` - Start in unknown consent mode
  * `giveConsent` - Grant consent at initialization
  * `logLevel` - Logging verbosity level (error, warning, info, debug, verbose)
  * `logger` - Custom logger implementation (SdkLogger interface)
  * `enableSDKLogs` - Enable SDK internal logging
  * `enableVisualWarnings` - Show visual warnings (toasts) for SDK errors/warnings
  * `customRequestHeaders` - Custom HTTP headers for requests
  * `deviceMetricOverrides` - Override collected device metrics
  * `sbs` - Initial SDK Behavior Settings
  * `disableOldDataMigration` - Disable migration from legacy native SDKs

* Events Module (sdk.events)
  * `record(key, count, sum, dur, segmentation)` - Record custom events with optional parameters
  * `recordMetrics(metricOverride)` - Record device metrics with optional overrides
  * Segmentation support for strings, numbers, booleans, and lists

* Views Module (sdk.views)
  * `startAutoStoppedView(viewName, {segmentation})` - Start an auto-stopped view
  * `endActiveView({segmentation})` - End the currently active view
  * Automatic view duration tracking with heartbeat mechanism
  * View state recovery after app restart

* Users Module (sdk.users)
  * `setProperties(props)` - Set user properties (named and custom)
  * `pushToArray(key, values)` - Add values to array property (allows duplicates)
  * `addToSet(key, values)` - Add unique values to array property
  * `pullFromArray(key, values)` - Remove values from array property
  * Named properties: name, username, email, organization, phone, picture, gender, byear

* Consents Module (sdk.consents)
  * `giveConsent()` - Grant consent for data collection
  * `revokeConsent()` - Revoke consent and clear data
  * Unknown consent state support

* Device ID Module (sdk.id)
  * `changeWithMerge(newDeviceId)` - Change device ID with server-side merge
  * `changeWithoutMerge(newDeviceId)` - Change device ID without merge (new user)
  * `deviceId` - Read-only access to current device ID
  * `deviceIdType` - Read-only access to device ID type (provided/generated)

* SDK Behavior Settings (SBS)
  * Server-side configuration support
  * Automatic SBS fetching and caching
  * Queue size limits (event/request queues)
  * Key/value length limits
  * Tracking control (global, events, views)
  * Event blacklist/whitelist filtering
  * User properties blacklist/whitelist filtering
  * Segmentation blacklist/whitelist filtering
  * Event-specific segmentation filtering

* Storage
  * Persistent storage support (SharedPreferences)
  * Memory-only storage mode
  * Custom storage methods override
  * Legacy native SDK data migration (Android/iOS)

* Networking
  * Automatic request queuing and retry
  * Request backoff mechanism
  * Custom HTTP headers support
  * Health check reporting

* Logging
  * Configurable log levels
  * Custom logger implementation support
  * Visual warnings (toasts) on Flutter
  