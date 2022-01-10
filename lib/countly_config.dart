import 'countly_flutter.dart';

class CountlyConfig {
  String _appKey;
  String _serverURL;
  String? _deviceID;
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

  /// Set custom crash segmentation which will be added to all recorded crashes
  /// [Map<String, dynamic> customCrashSegment] - crashSegment segmentation information. Accepted values are "Integer", "String", "Double", "Boolean"
  CountlyConfig setCustomCrashSegment(Map<String, dynamic> customCrashSegment){
    _customCrashSegment = customCrashSegment;
    return this;
  }


}
