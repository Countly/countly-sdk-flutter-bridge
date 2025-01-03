import 'configuration_interfaces/countly_config_apm.dart';
import 'configuration_interfaces/countly_config_content.dart';
import 'configuration_interfaces/countly_config_experimental.dart';
import 'configuration_interfaces/countly_config_limits.dart';
import 'countly_flutter.dart';
import 'remote_config.dart';

class CountlyConfig {
  String _appKey;
  String _serverURL;
  String? _deviceID;

  String? _locationCity;
  String? _locationIpAddress;
  String? _locationCountryCode;
  bool? _loggingEnabled;
  bool _locationDisabled = false;
  bool? _httpPostForced;
  Map<String, String>? _customNetworkRequestHeaders;
  String? _locationGpsCoordinates;
  String? _daCampaignType;
  String? _daCampaignData;
  List<String>? _consents;
  bool? _recordAppStartTime;
  int? _maxRequestQueueSize;
  bool? _manualSessionEnabled;
  bool? _shouldRequireConsent;
  String? _starRatingTextTitle;
  int? _eventQueueSizeThreshold;
  int? _sessionUpdateTimerDelay;
  String? _starRatingTextMessage;
  String? _starRatingTextDismiss;
  Map<String, String>? _location;
  String? _tamperingProtectionSalt;
  bool? _enableUnhandledCrashReporting;
  Map<String, String>? _iaAttributionValues;
  Map<String, dynamic>? _customCrashSegment;
  bool? _enableRemoteConfigAutomaticDownload;
  Map<String, dynamic>? _providedUserProperties;
  bool _remoteConfigAutomaticTriggers = false;
  final List<RCDownloadCallback> _remoteConfigGlobalCallbacks = [];
  bool _remoteConfigValueCaching = false;
  Map<String, Object>? _globalViewSegmentation;
  bool _enableAllConsents = false;
  bool _autoEnrollABOnDownload = false;
  int? _requestDropAgeHours;

  /// instance of CountlyConfigApm
  final CountlyConfigApm _countlyConfigApmInstance = CountlyConfigApm();

  /// instance of CountlyConfigExperimental
  final CountlyConfigExperimental _countlyConfigExperimentalInstance = CountlyConfigExperimental();

  /// instance of CountlyConfigLimits
  final CountlyConfigSDKInternalLimits _countlyConfigSDKInternalLimitsInstance = CountlyConfigSDKInternalLimits();

  /// instance of CountlyConfigContent
  final CountlyConfigContent _countlyConfigContentInstance = CountlyConfigContent();

  CountlyConfig(this._serverURL, this._appKey);

  /// Getters of private members
  String get appKey => _appKey;

  String? get deviceID => _deviceID;

  String get serverURL => _serverURL;

  String? get locationCity => _locationCity;

  String? get locationIpAddress => _locationIpAddress;

  String? get locationCountryCode => _locationCountryCode;

  List<String>? get consents => _consents;

  String? get locationGpsCoordinates => _locationGpsCoordinates;

  String? get daCampaignType => _daCampaignType;

  String? get daCampaignData => _daCampaignData;

  bool? get loggingEnabled => _loggingEnabled;

  bool get locationDisabled => _locationDisabled;

  bool? get httpPostForced => _httpPostForced;

  Map<String, String>? get location => _location;

  Map<String, String>? get customNetworkRequestHeaders => _customNetworkRequestHeaders;

  bool? get recordAppStartTime => _recordAppStartTime;

  int? get maxRequestQueueSize => _maxRequestQueueSize;

  bool? get manualSessionEnabled => _manualSessionEnabled;

  bool? get shouldRequireConsent => _shouldRequireConsent;

  String? get starRatingTextTitle => _starRatingTextTitle;

  String? get starRatingTextMessage => _starRatingTextMessage;

  String? get starRatingTextDismiss => _starRatingTextDismiss;

  int? get eventQueueSizeThreshold => _eventQueueSizeThreshold;

  int? get sessionUpdateTimerDelay => _sessionUpdateTimerDelay;

  String? get tamperingProtectionSalt => _tamperingProtectionSalt;

  Map<String, String>? get iaAttributionValues => _iaAttributionValues;

  Map<String, dynamic>? get customCrashSegment => _customCrashSegment;

  bool? get enableUnhandledCrashReporting => _enableUnhandledCrashReporting;

  Map<String, dynamic>? get providedUserProperties => _providedUserProperties;

  bool? get enableRemoteConfigAutomaticDownload => _enableRemoteConfigAutomaticDownload;

  bool get remoteConfigAutomaticTriggers => _remoteConfigAutomaticTriggers;

  List<RCDownloadCallback> get remoteConfigGlobalCallbacks => _remoteConfigGlobalCallbacks;

  bool get remoteConfigValueCaching => _remoteConfigValueCaching;

  Map<String, Object>? get globalViewSegmentation => _globalViewSegmentation;

  bool get enableAllConsents => _enableAllConsents;

  bool get autoEnrollABOnDownload => _autoEnrollABOnDownload;

  int? get requestDropAgeHours => _requestDropAgeHours;

  /// getter for CountlyConfigApm instance that is used to access CountlyConfigApm methods
  CountlyConfigApm get apm => _countlyConfigApmInstance;

  /// getter for CountlyConfigExperimental instance that is used to access CountlyConfigExperimental methods
  CountlyConfigExperimental get experimental => _countlyConfigExperimentalInstance;

  /// getter for CountlyConfigLimits instance that is used to access CountlyConfigLimits methods
  CountlyConfigSDKInternalLimits get sdkInternalLimits => _countlyConfigSDKInternalLimitsInstance;

  /// getter for CountlyConfigContent instance that is used to access CountlyConfigContent methods
  CountlyConfigContent get content => _countlyConfigContentInstance;

  /// URL of the Countly server to submit data to.
  /// Mandatory field.
  CountlyConfig setServerURL(String serverURL) {
    _serverURL = serverURL;
    return this;
  }

  /// app key for the application being tracked; find in the Countly Dashboard under Management &gt; Applications.
  /// Mandatory field.
  CountlyConfig setAppKey(String appKey) {
    _appKey = appKey;
    return this;
  }

  /// unique ID for the device the app is running on.
  CountlyConfig setDeviceId(String deviceID) {
    _deviceID = deviceID;
    return this;
  }

  /// enable temporary ID mode
  CountlyConfig enableTemporaryDeviceIDMode() {
    _deviceID = Countly.temporaryDeviceID;
    return this;
  }

  /// Set to true of you want to enable countly internal debugging logs
  /// those logs will be printed to the console
  CountlyConfig setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
    return this;
  }

  /// Call this to disable location tracking
  CountlyConfig disableLocation() {
    _locationDisabled = true;
    return this;
  }

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  CountlyConfig setParameterTamperingProtectionSalt(String salt) {
    _tamperingProtectionSalt = salt;
    return this;
  }

  /// Set the threshold for event grouping. Event count that is below the
  /// threshold will be sent on update ticks.
  CountlyConfig setEventQueueSizeToSend(int threshold) {
    _eventQueueSizeThreshold = threshold;
    return this;
  }

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  /// [int delay] - delay in seconds
  CountlyConfig setUpdateSessionTimerDelay(int delay) {
    _sessionUpdateTimerDelay = delay;
    return this;
  }

  /// Set custom crash segmentation which will be added to all recorded crashes
  /// [Map<String, dynamic> customCrashSegment] - crashSegment segmentation information. Accepted values are "Integer", "String", "Double", "Boolean"
  CountlyConfig setCustomCrashSegment(Map<String, dynamic> customCrashSegment) {
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

  /// Set if you want custom HTTP headers to be used for all requests
  CountlyConfig setCustomNetworkRequestHeaders(Map<String, String>? customNetworkRequestHeaders) {
    _customNetworkRequestHeaders = customNetworkRequestHeaders;
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

  /// Enables the recording of the app start time.
  /// This is now deprecated, use [CountlyConfig.apm.enableAppStartTimeTracking] instead
  CountlyConfig setRecordAppStartTime(bool recordAppStartTime) {
    _recordAppStartTime = recordAppStartTime;
    return this;
  }

  /// Call to enable uncaught crash reporting
  CountlyConfig enableCrashReporting() {
    _enableUnhandledCrashReporting = true;
    return this;
  }

  /// Set user location
  /// [String country_code] - ISO Country code for the user's country
  /// [String city] - Name of the user's city
  /// [String gpsCoordinates] - comma separate lat and lng values. For example, "56.42345,123.45325"
  /// [String ipAddress] - ip address
  CountlyConfig setLocation({String? countryCode, String? city, String? gpsCoordinates, String? ipAddress}) {
    _locationCountryCode = countryCode;
    _locationCity = city;
    _locationGpsCoordinates = gpsCoordinates;
    _locationIpAddress = ipAddress;
    return this;
  }

  /// This flag limits the number of requests that can be stored in the request queue when the Countly server is unavailable or unreachable.
  /// If the number of requests in the queue reaches the limit, the oldest requests in the queue will be dropped.
  /// [int maxSize] - Minimum value is "1".
  /// [int maxSize] - Default value is 1,000.
  CountlyConfig setMaxRequestQueueSize(int maxSize) {
    _maxRequestQueueSize = maxSize;
    return this;
  }

  /// Enable manual session handling
  CountlyConfig enableManualSessionHandling() {
    _manualSessionEnabled = true;
    return this;
  }

  @Deprecated('This function is deprecated, please use remoteConfigRegisterGlobalCallback instead')
  /// If enable, will automatically download newest remote config values.
  /// enabled set true for enabling it
  /// callback callback called after the update was done
  CountlyConfig setRemoteConfigAutomaticDownload(bool enabled, Function(String? error) callback) {
    _enableRemoteConfigAutomaticDownload = enabled;
    Countly.setRemoteConfigCallback(callback);
    return this;
  }

  /// Report direct user attribution
  CountlyConfig recordDirectAttribution(String campaignType, String campaignData) {
    _daCampaignType = campaignType;
    _daCampaignData = campaignData;
    return this;
  }

  /// Report indirect user attribution
  CountlyConfig recordIndirectAttribution(Map<String, String> attributionValues) {
    _iaAttributionValues = attributionValues;
    return this;
  }

  /// Used to provide user properties that would be sent as soon as possible
  CountlyConfig setUserProperties(Map<String, dynamic> userProperties) {
    _providedUserProperties = userProperties;
    return this;
  }

  /// Used to provide user properties that would be sent as soon as possible
  CountlyConfig enableRemoteConfigAutomaticTriggers() {
    _remoteConfigAutomaticTriggers = true;
    return this;
  }

  /// Used to register global callback for RC
  CountlyConfig remoteConfigRegisterGlobalCallback(RCDownloadCallback callback) {
    _remoteConfigGlobalCallbacks.add(callback);
    return this;
  }

  /// Used to disable RC Value caching
  CountlyConfig enableRemoteConfigValueCaching() {
    _remoteConfigValueCaching = true;
    return this;
  }

  /// Used to enable global view segmentation
  CountlyConfig setGlobalViewSegmentation(Map<String, Object> segmentation) {
    _globalViewSegmentation = segmentation;
    return this;
  }

  /// Used to give all consent at init time
  CountlyConfig giveAllConsents() {
    _enableAllConsents = true;
    return this;
  }

  /// This is used for enrolling user to AB testing on RC download
  CountlyConfig enrollABOnRCDownload() {
    _autoEnrollABOnDownload = true;
    return this;
  }

  /// This would set a time frame in which the requests older than the given hours would be dropped while sending a request
  /// Ex: Setting this to 10 would mean any requests created more than 10 hours ago would be dropped if they were in the queue
  /// [int dropAgeHours] A positive integer. Requests older than the 'dropAgeHours' (with respect to now) would be dropped
  CountlyConfig setRequestDropAgeHours(int dropAgeHours) {
    _requestDropAgeHours = dropAgeHours;
    return this;
  }
}
