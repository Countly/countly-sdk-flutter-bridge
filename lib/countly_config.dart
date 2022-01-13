import 'countly_flutter.dart';

class CountlyConfig {
  String _appKey;
  String _serverURL;
  String? _deviceID;

  List<String>? _consents;
  bool? _loggingEnabled = false;
  bool? _httpPostForced = false;
  String? _starRatingTextTitle;
  int? _eventQueueSizeThreshold;
  int? _sessionUpdateTimerDelay;
  String? _starRatingTextMessage;
  String? _starRatingTextDismiss;
  String? _tamperingProtectionSalt;
  bool? _shouldRequireConsent = false;
  Map<String, dynamic>? _customCrashSegment;

  CountlyConfig(this._serverURL, this._appKey);

  /// Getters of private members
  String get serverURL => _serverURL;
  String get appKey => _appKey;
  String? get deviceID => _deviceID;
  List<String>? get consents => _consents;
  bool? get loggingEnabled => _loggingEnabled;
  bool? get httpPostForced => _httpPostForced;
  String? get starRatingTextTitle => _starRatingTextTitle;
  int? get eventQueueSizeThreshold => _eventQueueSizeThreshold;
  int? get sessionUpdateTimerDelay => _sessionUpdateTimerDelay;
  String? get starRatingTextMessage => _starRatingTextMessage;
  String? get starRatingTextDismiss => _starRatingTextDismiss;
  String? get tamperingProtectionSalt => _tamperingProtectionSalt;
  bool? get shouldRequireConsent => _shouldRequireConsent;
  Map<String, dynamic>? get customCrashSegment => _customCrashSegment;

  /// URL of the Countly server to submit data to.
  /// Mandatory field.
  CountlyConfig setServerURL(String serverURL) {
    _serverURL = serverURL;
    return this;
  }

  /// app key for the application being tracked; find in the Countly Dashboard under Management &gt; Applications.
  // Mandatory field.
  CountlyConfig setAppKey(String appKey) {
    _appKey = appKey;
    return this;
  }

  /// unique ID for the device the app is running on.
  CountlyConfig setDeviceId(String deviceID) {
    _deviceID = deviceID;
    return this;
  }

  /// Set to true of you want to enable countly internal debugging logs
  /// those logs will be printed to the console
  CountlyConfig setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
    return this;
  }

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  CountlyConfig setParameterTamperingProtectionSalt(String salt) {
    _tamperingProtectionSalt = salt;
    return this;
  }

  /// Set the threshold for event grouping. Event count that is bellow the
  /// threshold will be sent on update ticks.
  CountlyConfig setEventQueueSizeToSend(int threshold) {
    _eventQueueSizeThreshold = threshold;
    return this;
  }

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  // [int delay] - delay in seconds
  CountlyConfig setUpdateSessionTimerDelay(int delay) {
    _sessionUpdateTimerDelay = delay;
    return this;
  }

  /// Set custom crash segmentation which will be added to all recorded crashes
  /// [Map<String, dynamic> customCrashSegment] - crashSegment segmentation information. Accepted values are "Integer", "String", "Double", "Boolean"
  CountlyConfig setCustomCrashSegment(Map<String, dynamic> customCrashSegment){
    _customCrashSegment = customCrashSegment;
    return this;
  }

  /// Set if consent should be required
  CountlyConfig setRequiresConsent(bool shouldRequireConsent) {
  _shouldRequireConsent = shouldRequireConsent;
  return this;
  }

  /// Sets which features are enabled in case consent is required
  CountlyConfig setConsentEnabled(List<String> consents) {
    _consents = consents;
    return this;
  }

  /// Set to 'true' if you want HTTP POST to be used for all requests
  CountlyConfig setHttpPostForced(bool isForced) {
    _httpPostForced = isForced;
    return this;
  }

  /// the shown title text for the star rating dialogs.
  /// Currently implemented for Android only
  CountlyConfig setStarRatingTextTitle(String starRatingTextTitle) {
    _starRatingTextTitle = starRatingTextTitle;
    return this;
  }

  /// the shown message text for the star rating dialogs.
  CountlyConfig setStarRatingTextMessage(String starRatingTextMessage) {
    _starRatingTextMessage = starRatingTextMessage;
    return this;
  }

  /// the shown dismiss button text for the shown star rating dialogs.
  /// Currently implemented for Android only
  CountlyConfig setStarRatingTextDismiss(String starRatingTextDismiss) {
    _starRatingTextDismiss = starRatingTextDismiss;
    return this;
  }
}
