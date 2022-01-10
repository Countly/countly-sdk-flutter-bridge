import 'countly_flutter.dart';

class CountlyConfig {
  String _appKey;
  String _serverURL;
  String? _deviceID;
  bool _loggingEnabled = false;
  String? _tamperingProtectionSalt;
  int? _eventQueueSizeThreshold;
  int? _sessionUpdateTimerDelay;
  Map<String, dynamic> _customCrashSegment = {};

  CountlyConfig(this._serverURL, this._appKey) {
    if(_serverURL.isEmpty) {
      Countly.log('CountlyConfig, serverURL cannot be empty', logLevel: LogLevel.WARNING);
    }
    if(_appKey.isEmpty) {
      Countly.log('CountlyConfig, appKey cannot be empty', logLevel: LogLevel.WARNING);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> countlyConfig = {};
    countlyConfig['appKey'] = _appKey;
    countlyConfig['serverURL'] = _serverURL;
    if (_customCrashSegment != null) {
      countlyConfig['customCrashSegment'] = {};
      _customCrashSegment!.forEach((key, value) {
        countlyConfig['customCrashSegment'][key] = value.toString();
      });
    }
    if(_deviceID != null) {
      countlyConfig['deviceID'] = _deviceID;
    }

    if(_tamperingProtectionSalt != null) {
      countlyConfig['tamperingProtectionSalt'] = _tamperingProtectionSalt;
    }
    if(_eventQueueSizeThreshold != null) {
      countlyConfig['eventQueueSizeThreshold'] = _eventQueueSizeThreshold;
    }
    if(_sessionUpdateTimerDelay != null) {
      countlyConfig['sessionUpdateTimerDelay'] = _sessionUpdateTimerDelay;
    }

    countlyConfig['loggingEnabled'] = _loggingEnabled;
    return countlyConfig;
  }

  /// URL of the Countly server to submit data to.
  /// Mandatory field.
  CountlyConfig setServerURL(String serverURL) {
    if(serverURL.isEmpty) {
      Countly.log('CountlyConfig, serverURL cannot be empty', logLevel: LogLevel.WARNING);
    }
    _serverURL = serverURL;
    return this;
  }

  /// app key for the application being tracked; find in the Countly Dashboard under Management &gt; Applications.
  // Mandatory field.
  CountlyConfig setAppKey(String appKey) {
    if(appKey.isEmpty) {
      Countly.log('CountlyConfig, appKey cannot be empty', logLevel: LogLevel.WARNING);
    }
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
    Countly.isDebug = enabled;
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



}
