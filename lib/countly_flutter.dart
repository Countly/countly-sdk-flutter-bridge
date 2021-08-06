import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:pedantic/pedantic.dart';

enum LogLevel { INFO, DEBUG, VERBOSE, WARNING, ERROR }

class Countly {
  static const MethodChannel _channel = MethodChannel('countly_flutter');

  /// Used to determine if log messages should be printed to the console
  /// its value should be updated from [setLoggingEnabled(bool flag)].
  static bool _isDebug = false;

  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  static bool _isInitialized = false;

  static final String tag = 'CountlyFlutter';

  /// Flag to determine if crash logging functionality should be enabled
  /// If false the intercepted crashes will be ignored
  /// Set true when user enabled crash logging
  static bool _enableCrashReportingFlag = false;

  static Map<String, String> messagingMode = {
    'TEST': '1',
    'PRODUCTION': '0',
    'ADHOC': '2'
  };
  static Map<String, String> deviceIDType = {
    'TemporaryDeviceID': 'TemporaryDeviceID'
  };

  static void log(String? message, {LogLevel logLevel = LogLevel.DEBUG}) async {
    String logLevelStr = describeEnum(logLevel);
    if (_isDebug) {
      print('[$tag] $logLevelStr: $message');
    }
  }

  static Future<String?> init(String serverUrl, String appKey,
      [String? deviceId]) async {
    _isInitialized = true;
    if (Platform.isAndroid) {
      messagingMode = {'TEST': '2', 'PRODUCTION': '0'};
    }
    List<String> args = [];
    args.add(serverUrl);
    args.add(appKey);
    if (deviceId != null) {
      args.add(deviceId);
    }
    log(args.toString());
    final String? result = await _channel
        .invokeMethod('init', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<bool> isInitialized() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'isInitialized', <String, dynamic>{'data': json.encode(args)});
    if (result == 'true') {
      return true;
    } else {
      return false;
    }
  }

  /// Replaces all requests with a different app key with the current app key.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests' app key will be replaced with the current app key.
  static Future<String?> replaceAllAppKeysInQueueWithCurrentAppKey() async {
    final String? result = await _channel
        .invokeMethod('replaceAllAppKeysInQueueWithCurrentAppKey');
    log(result);
    return result;
  }

  /// Removes all requests with a different app key in request queue.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests will be removed from request queue.
  static Future<String?> removeDifferentAppKeysFromQueue() async {
    final String? result =
        await _channel.invokeMethod('removeDifferentAppKeysFromQueue');
    log(result);
    return result;
  }

  /// Call this function when app is loaded, so that the app launch duration can be recorded.
  /// Should be called after init.
  static Future<String?> appLoadingFinished() async {
    if (!_isInitialized) {
      log('appLoadingFinished, init must be called before appLoadingFinished',
          logLevel: LogLevel.WARNING);
      return 'init must be called before appLoadingFinished';
    }
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'appLoadingFinished', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static bool isNullOrEmpty(String? s) => s == null || s.isEmpty;

  static Future<String?> recordEvent(Map<String, Object> options) async {
    List<String> args = [];
    options['key'] ??= '';
    String eventKey = options['key'].toString();

    if (eventKey.isEmpty) {
      String error = 'recordEvent, Valid Countly event key is required';
      log(error);
      return 'Error : $error';
    }
    args.add(eventKey);
    options['count'] ??= 1;
    args.add(options['count'].toString());

    options['sum'] ??= '0';
    args.add(options['sum'].toString());

    options['duration'] ??= '0';
    args.add(options['duration'].toString());

    if (options['segmentation'] != null) {
      var segmentation = options['segmentation'] as Map;
      segmentation.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }

    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'recordEvent', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Record custom view to Countly.
  ///
  /// [String view] - name of the view
  /// [Map<String, Object> segmentation] - allows to add optional segmentation,
  /// Supported data type for segmentation values are String, int, double and bool
  static Future<String?> recordView(String view,
      [Map<String, Object>? segmentation]) async {
    if (view.isEmpty) {
      String error =
          'recordView, Trying to record view with empty view name, ignoring request';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(view);
    if (segmentation != null) {
      segmentation.forEach((k, v) {
        if (v is String || v is int || v is double || v is bool) {
          args.add(k);
          args.add(v.toString());
        } else {
          log('recordView, unsupported segmentation data type [${v.runtimeType}], View [$view]',
              logLevel: LogLevel.WARNING);
        }
      });
    }
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'recordView', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> setUserData(Map<String, Object> options) async {
    List<String> args = [];
    options['name'] ??= '';
    options['username'] ??= '';
    options['email'] ??= '';
    options['organization'] ??= '';
    options['phone'] ??= '';
    options['picture'] ??= '';
    options['picturePath'] ??= '';
    options['gender'] ??= '';
    options['byear'] ??= '0';

    args.add(options['name'].toString());
    args.add(options['username'].toString());
    args.add(options['email'].toString());
    args.add(options['organization'].toString());
    args.add(options['phone'].toString());
    args.add(options['picture'].toString());
    args.add(options['picturePath'].toString());
    args.add(options['gender'].toString());
    args.add(options['byear'].toString());

    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setuserdata', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// This method will ask for permission, enables push notification and send push token to countly server.
  /// Should be call after Countly init
  static Future<String?> askForNotificationPermission() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'askForNotificationPermission',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Disable push notifications feature, by default it is enabled.
  /// Currently implemented for iOS only
  /// Should be called before Countly init
  static Future<String?> disablePushNotifications() async {
    if (!Platform.isIOS) {
      return 'disablePushNotifications : To be implemented';
    }
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'disablePushNotifications',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set messaging mode for push notifications
  /// Should be call before Countly init
  static Future<String?> pushTokenType(String tokenType) async {
    if (tokenType.isEmpty) {
      String error = 'pushTokenType, tokenType cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(tokenType);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'pushTokenType', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set callback to receive push notifications
  /// @param { callback listner } callback
  static Future<String?> onNotification(Function callback) async {
    List<String> args = [];
    log('registerForNotification');
    await _channel.invokeMethod('registerForNotification',
        <String, dynamic>{'data': json.encode(args)}).then((value) {
      callback(value.toString());
      onNotification(callback);
    }).catchError((error) {
      callback(error.toString());
    });
    return '';
  }

  static Future<String?> start() async {
    List<String> args = [];
    final String? result = await _channel
        .invokeMethod('start', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> manualSessionHandling() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'manualSessionHandling', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> stop() async {
    List<String> args = [];
    final String? result = await _channel
        .invokeMethod('stop', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> updateSessionPeriod() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'updateSessionPeriod', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  /// [int sessionInterval]- delay in seconds
  static Future<String?> updateSessionInterval(int sessionInterval) async {
    if (_isInitialized) {
      log('updateSessionInterval should be called before init',
          logLevel: LogLevel.WARNING);
      return 'updateSessionInterval should be called before init';
    }
    List<String> args = [];
    args.add(sessionInterval.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'updateSessionInterval', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Events get grouped together and are sent either every minute or after the unsent event count reaches a threshold. By default it is 10
  /// Should be call before Countly init
  static Future<String?> eventSendThreshold(int limit) async {
    List<String> args = [];
    args.add(limit.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'eventSendThreshold', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> storedRequestsLimit() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'storedRequestsLimit', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> setOptionalParametersForInitialization(
      Map<String, Object> options) async {
    List<String> args = [];

    options['city'] ??= 'null';
    options['country'] ??= 'null';
    options['latitude'] ??= 'null';
    options['longitude'] ??= 'null';
    options['ipAddress'] ??= 'null';

    String? city = options['city'].toString();
    String country = options['country'].toString();
    String latitude = options['latitude'].toString();
    String longitude = options['longitude'].toString();
    String ipAddress = options['ipAddress'].toString();

    args.add(city);
    args.add(country);
    args.add(latitude);
    args.add(longitude);
    args.add(ipAddress);

    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setOptionalParametersForInitialization',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Get currently used device Id.
  /// Should be call after Countly init
  static Future<String?> getCurrentDeviceId() async {
    if (!_isInitialized) {
      log('getCurrentDeviceId, init must be called before getCurrentDeviceId',
          logLevel: LogLevel.WARNING);
      return 'init must be called before getCurrentDeviceId';
    }
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'getCurrentDeviceId', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> changeDeviceId(
      String newDeviceID, bool onServer) async {
    if (newDeviceID.isEmpty) {
      String error = 'changeDeviceId, deviceId cannot be null or empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    String onServerString;
    if (onServer == false) {
      onServerString = '0';
    } else {
      onServerString = '1';
    }
    args.add(newDeviceID);
    args.add(onServerString);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'changeDeviceId', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> addCrashLog(String logs) async {
    if (logs.isEmpty) {
      String error = "addCrashLog, Can't add a null or empty crash logs";
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(logs);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'addCrashLog', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set to true if you want to enable countly internal debugging logs
  /// Should be call before Countly init
  static Future<String?> setLoggingEnabled(bool flag) async {
    List<String> args = [];
    _isDebug = flag;
    args.add(flag.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setLoggingEnabled', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  /// Should be call before Countly init
  static Future<String?> enableParameterTamperingProtection(String salt) async {
    if (salt.isEmpty) {
      String error = 'enableParameterTamperingProtection, salt cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(salt);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'enableParameterTamperingProtection',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set to 'true' if you want HTTP POST to be used for all requests
  /// Should be call before Countly init
  static Future<String?> setHttpPostForced(bool isEnabled) async {
    List<String> args = [];
    args.add(isEnabled.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setHttpPostForced', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set user initial location
  /// Should be call before init
  static Future<String?> setLocationInit(String countryCode, String city,
      String gpsCoordinates, String ipAddress) async {
    List<String> args = [];
    args.add(countryCode);
    args.add(city);
    args.add(gpsCoordinates);
    args.add(ipAddress);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setLocationInit', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> setLocation(String latitude, String longitude) async {
    if (latitude.isEmpty) {
      String error = 'setLocation, latitude cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (longitude.isEmpty) {
      String error = 'setLocation, longitude cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];

    args.add(latitude);
    args.add(longitude);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setLocation', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> setProperty(String keyName, String keyValue) async {
    if (keyName.isEmpty) {
      String error = 'setProperty, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (keyValue.isEmpty) {
      String error = 'setProperty, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(keyValue);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_setProperty', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> increment(String keyName) async {
    if (keyName.isEmpty) {
      String error = 'increment, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_increment', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> incrementBy(String keyName, int keyIncrement) async {
    if (keyName.isEmpty) {
      String error = 'incrementBy, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(keyIncrement.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_incrementBy', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> multiply(String keyName, int multiplyValue) async {
    if (keyName.isEmpty) {
      String error = 'multiply, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(multiplyValue.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_multiply', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> saveMax(String keyName, int saveMax) async {
    if (keyName.isEmpty) {
      String error = 'saveMax, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(saveMax.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_saveMax', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> saveMin(String keyName, int saveMin) async {
    if (keyName.isEmpty) {
      String error = 'saveMin, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(saveMin.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_saveMin', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> setOnce(String keyName, String setOnce) async {
    if (keyName.isEmpty) {
      String error = 'setOnce, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (setOnce.isEmpty) {
      String error = 'setOnce, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(setOnce);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_setOnce', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> pushUniqueValue(
      String type, String pushUniqueValue) async {
    if (type.isEmpty) {
      String error = 'pushUniqueValue, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (pushUniqueValue.isEmpty) {
      String error = 'pushUniqueValue, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(type);
    args.add(pushUniqueValue);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_pushUniqueValue',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> pushValue(String type, String pushValue) async {
    if (type.isEmpty) {
      String error = 'pushValue, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (pushValue.isEmpty) {
      String error = 'pushValue, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(type);
    args.add(pushValue);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_pushValue', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> pullValue(String type, String pullValue) async {
    if (type.isEmpty) {
      String error = 'pullValue, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (pullValue.isEmpty) {
      String error = 'pullValue, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(type);
    args.add(pullValue);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'userData_pullValue', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set that consent should be required for features to work.
  /// Should be call before Countly init
  static Future<String?> setRequiresConsent(bool flag) async {
    List<String> args = [];
    args.add(flag.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setRequiresConsent', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Give consent for specific features.
  /// Should be call before Countly init
  static Future<String?> giveConsentInit(List<String> consents) async {
    if (consents.isEmpty) {
      String error = 'giveConsentInit, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(consents.toString());
    final String? result = await _channel.invokeMethod(
        'giveConsentInit', <String, dynamic>{'data': json.encode(consents)});
    log(result);
    return result;
  }

  static Future<String?> giveConsent(List<String> consents) async {
    if (consents.isEmpty) {
      String error = 'giveConsent, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(consents.toString());
    final String? result = await _channel.invokeMethod(
        'giveConsent', <String, dynamic>{'data': json.encode(consents)});
    log(result);
    return result;
  }

  static Future<String?> removeConsent(List<String> consents) async {
    if (consents.isEmpty) {
      String error = 'removeConsent, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(consents.toString());
    final String? result = await _channel.invokeMethod(
        'removeConsent', <String, dynamic>{'data': json.encode(consents)});
    log(result);
    return result;
  }

  /// Give consent for all features
  /// Should be call after Countly init
  static Future<String?> giveAllConsent() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'giveAllConsent', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> removeAllConsent() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'removeAllConsent', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
  /// Should be call before Countly init
  static Future<String?> setRemoteConfigAutomaticDownload(
      Function callback) async {
    List<String> args = [];
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setRemoteConfigAutomaticDownload',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    callback(result);
    return result;
  }

  static Future<String?> remoteConfigUpdate(Function callback) async {
    List<String> args = [];

    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'remoteConfigUpdate', <String, dynamic>{'data': json.encode(args)});
    log(result);
    callback(result);
    return result;
  }

  static Future<String?> updateRemoteConfigForKeysOnly(
      List<String> keys, Function callback) async {
    if (keys.isEmpty) {
      String error = 'updateRemoteConfigForKeysOnly, keys List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(keys.toString());
    final String? result = await _channel.invokeMethod(
        'updateRemoteConfigForKeysOnly',
        <String, dynamic>{'data': json.encode(keys)});
    log(result);
    callback(result);
    return result;
  }

  static Future<String?> updateRemoteConfigExceptKeys(
      List<String> keys, Function callback) async {
    if (keys.isEmpty) {
      String error = 'updateRemoteConfigExceptKeys, keys List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(keys.toString());
    final String? result = await _channel.invokeMethod(
        'updateRemoteConfigExceptKeys',
        <String, dynamic>{'data': json.encode(keys)});
    log(result);
    callback(result);
    return result;
  }

  static Future<String?> remoteConfigClearValues(Function callback) async {
    List<String> args = [];
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'remoteConfigClearValues',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    callback(result);
    return result;
  }

  static Future<String?> getRemoteConfigValueForKey(
      String key, Function callback) async {
    if (key.isEmpty) {
      String error = 'getRemoteConfigValueForKey, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(key);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'getRemoteConfigValueForKey',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    callback(result);
    return result;
  }

  /// Set's the text's for the different fields in the star rating dialog. Set value null if for some field you want to keep the old value
  /// [String starRatingTextTitle] - dialog's title text (Only for Android)
  /// [String starRatingTextMessage] - dialog's message text
  /// [String starRatingTextDismiss] - dialog's dismiss buttons text (Only for Android)
  static Future<String?> setStarRatingDialogTexts(String starRatingTextTitle,
      String starRatingTextMessage, String starRatingTextDismiss) async {
    List<String> args = [];
    args.add(starRatingTextTitle);
    args.add(starRatingTextMessage);
    args.add(starRatingTextDismiss);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setStarRatingDialogTexts',
        <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> askForStarRating() async {
    List<String> args = [];
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'askForStarRating', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> askForFeedback(
      String widgetId, String? closeButtonText) async {
    if (widgetId.isEmpty) {
      String error = 'askForFeedback, widgetId cannot be empty';
      log(error);
      return 'Error : $error';
    }
    closeButtonText = closeButtonText ??= '';
    List<String> args = [];
    args.add(widgetId);
    args.add(closeButtonText);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'askForFeedback', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Get a list of available feedback widgets for this device ID
  static Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets() async {
    List<CountlyPresentableFeedback> presentableFeedback = [];
    String? error;
    try {
      final List<dynamic> retrievedWidgets =
          await _channel.invokeMethod('getAvailableFeedbackWidgets');
      presentableFeedback =
          retrievedWidgets.map(CountlyPresentableFeedback.fromJson).toList();
    } on PlatformException catch (e) {
      error = e.message;
      log('getAvailableFeedbackWidgets Error : $error');
    }
    FeedbackWidgetsResponse feedbackWidgetsResponse =
        FeedbackWidgetsResponse(presentableFeedback, error);

    return feedbackWidgetsResponse;
  }

  /// Present a chosen feedback widget
  /// [CountlyPresentableFeedback widgetInfo] - Get available list of feedback widgets by calling 'getAvailableFeedbackWidgets()' and pass the widget object as a parameter.
  /// [String closeButtonText] - Text for cancel/close button.
  static Future<String?> presentFeedbackWidget(
      CountlyPresentableFeedback widgetInfo, String closeButtonText) async {
    List<String> args = [];
    args.add(widgetInfo.widgetId);
    args.add(widgetInfo.type);
    args.add(closeButtonText);
    log(args.toString());
    String? result;
    try {
      result = await _channel.invokeMethod('presentFeedbackWidget',
          <String, dynamic>{'data': json.encode(args)});
    } on PlatformException catch (e) {
      result = e.message;
    }
    log(result);
    return result;
  }

  /// Downloads widget info and returns [widgetData, error]
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which you want to download widget data
  static Future<List> getFeedbackWidgetData(
      CountlyPresentableFeedback widgetInfo) async {
    Map<String, dynamic> widgetData = Map<String, dynamic>();
    if (!Platform.isAndroid) {
      String error = 'getFeedbackWidgetData : To be implemented';
      return [widgetData, error];
    }
    String? error;
    List<String> args = [];
    args.add(widgetInfo.widgetId);
    args.add(widgetInfo.type);
    args.add(widgetInfo.name);
    log(args.toString());
    try {
      Map<dynamic, dynamic> retrievedWidgetData = await _channel.invokeMethod(
          'getFeedbackWidgetData',
          <String, dynamic>{'data': json.encode(args)});
      widgetData = Map<String, dynamic>.from(retrievedWidgetData);
    } on PlatformException catch (e) {
      error = e.message;
      log('getAvailableFeedbackWidgets Error : $error');
    }
    return [widgetData, error];
  }

  /// Report widget info and do data validation
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which the feedback is filled out
  /// [Map<String, dynamic> widgetData] - widget data for this specific widget
  /// [Map<String, Object> widgetResult] - segmentation of the filled out feedback. If this segmentation is null, it will be assumed that the survey was closed before completion and mark it appropriately
  static Future<String?> reportFeedbackWidgetManually(
      CountlyPresentableFeedback widgetInfo,
      Map<String, dynamic> widgetData,
      Map<String, Object> widgetResult) async {
    if (!Platform.isAndroid) {
      return 'reportFeedbackWidgetManually : To be implemented';
    }
    List<String> widgetInfoList = [];
    widgetInfoList.add(widgetInfo.widgetId);
    widgetInfoList.add(widgetInfo.type);
    widgetInfoList.add(widgetInfo.name);

    List<dynamic> args = [];
    args.add(widgetInfoList);
    args.add(widgetData);
    args.add(widgetResult);
    log(args.toString());
    String? result;
    try {
      result = await _channel.invokeMethod('reportFeedbackWidgetManually',
          <String, dynamic>{'data': json.encode(args)});
    } on PlatformException catch (e) {
      result = e.message;
    }
    log(result);
    return result;
  }

  static Future<String?> startEvent(String key) async {
    if (key.isEmpty) {
      String error = "startEvent, Can't start event with empty key";
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(key);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'startEvent', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> endEvent(Map<String, Object> options) async {
    List<String> args = [];
    var segmentation = {};
    String eventKey = options['key'] != null ? options['key'].toString() : '';

    if (eventKey.isEmpty) {
      String error = "endEvent, Can't end event with a null or empty key";
      log(error);
      return 'Error : $error';
    }
    args.add(eventKey);

    options['count'] ??= 1;
    args.add(options['count'].toString());

    options['sum'] ??= '0';
    args.add(options['sum'].toString());

    if (options['segmentation'] != null) {
      segmentation = options['segmentation'] as Map;
      segmentation.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    log(args.toString());
    final String? result = await _channel
        .invokeMethod('endEvent', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Call used for testing error handling
  /// Should not be used
  static Future<String?> throwNativeException() async {
    List<String> args = [];
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'throwNativeException', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Enable crash reporting to report uncaught errors to Countly.
  /// Should be call before Countly init
  static Future<String?> enableCrashReporting() async {
    FlutterError.onError = _recordFlutterError;
    List<String> args = [];
    _enableCrashReportingFlag = true;
    final String? result = await _channel.invokeMethod(
        'enableCrashReporting', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// This call does not add a stacktrace automatically
  /// if it's needed, it should already be added to the [exception] variable
  ///
  /// A potential use case would be to provide [exception.toString()]
  ///
  /// [String exception] - the exception / crash information sent to the server
  /// [bool nonfatal] - reports if the error was fatal or not
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  static Future<String?> logException(String exception, bool nonfatal,
      [Map<String, Object>? segmentation]) async {
    List<String> args = [];
    args.add(exception);
    args.add(nonfatal.toString());
    if (segmentation != null) {
      segmentation.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    final String? result = await _channel.invokeMethod(
        'logException', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Set optional key/value segment added for crash reports.
  /// Should be call before Countly init
  static Future<String?> setCustomCrashSegment(
      Map<String, Object> segments) async {
    List<String> args = [];
    segments.forEach((k, v) {
      args.add(k.toString());
      args.add(v.toString());
    });
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'setCustomCrashSegment', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> startTrace(String traceKey) async {
    List<String> args = [];
    args.add(traceKey);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'startTrace', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> cancelTrace(String traceKey) async {
    List<String> args = [];
    args.add(traceKey);
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'cancelTrace', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> clearAllTraces() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'clearAllTraces', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> endTrace(
      String traceKey, Map<String, int>? customMetric) async {
    List<String> args = [];
    args.add(traceKey);
    if (customMetric != null) {
      customMetric.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    log(args.toString());
    final String? result = await _channel
        .invokeMethod('endTrace', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  static Future<String?> recordNetworkTrace(
      String networkTraceKey,
      int responseCode,
      int requestPayloadSize,
      int responsePayloadSize,
      int startTime,
      int endTime) async {
    List<String> args = [];
    args.add(networkTraceKey);
    args.add(responseCode.toString());
    args.add(requestPayloadSize.toString());
    args.add(responsePayloadSize.toString());
    args.add(startTime.toString());
    args.add(endTime.toString());
    log(args.toString());
    final String? result = await _channel.invokeMethod(
        'recordNetworkTrace', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Enable APM features, which includes the recording of app start time.
  /// Should be call before Countly init
  static Future<String?> enableApm() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'enableApm', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception is provided with an [Exception] object
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String exception] - the exception that is recorded
  /// [bool nonfatal] - reports if the exception was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  static Future<String?> logExceptionEx(Exception exception, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation}) async {
    stacktrace ??= StackTrace.current;
    final result = logException(
        '${exception.toString()}\n\n$stacktrace', nonfatal, segmentation);
    return result;
  }

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception/error is provided with a string message
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String message] - the error / crash information sent to the server
  /// [bool nonfatal] - reports if the error was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  static Future<String?> logExceptionManual(String message, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation}) async {
    stacktrace ??= StackTrace.current;
    final result =
        logException('$message\n\n$stacktrace', nonfatal, segmentation);
    return result;
  }

  /// Internal callback to record 'FlutterError.onError' errors
  ///
  /// Must call [enableCrashReporting()] to enable it
  static Future<void> _recordFlutterError(FlutterErrorDetails details) async {
    log('_recordFlutterError, Flutter error caught by Countly:');
    if (!_enableCrashReportingFlag) {
      log('_recordFlutterError, Crash Reporting must be enabled to report crash on Countly',
          logLevel: LogLevel.WARNING);
      return;
    }

    unawaited(
        _internalRecordError(details.exceptionAsString(), details.stack));
  }

  /// Callback to catch and report Dart errors, [enableCrashReporting()] must call before [init] to make it work.
  ///
  /// This callback has to be provided when the app is about to be run.
  /// It has to be done inside a custom Zone by providing [Countly.recordDartError] in onError() callback.
  ///
  /// ```
  /// void main() {
  ///   runZonedGuarded<Future<void>>(() async {
  ///     runApp(MyApp());
  ///   }, Countly.recordDartError);
  /// }
  ///
  static Future<void> recordDartError(dynamic exception, StackTrace stack,
      {dynamic context}) async {
    log('recordError, Error caught by Countly :');
    if (!_enableCrashReportingFlag) {
      log('recordError, Crash Reporting must be enabled to report crash on Countly',
          logLevel: LogLevel.WARNING);
      return;
    }
    unawaited(_internalRecordError(exception, stack));
  }

  /// A common call for crashes coming from [_recordFlutterError] and [recordDartError]
  ///
  /// They are then further reported to countly
  static Future<void> _internalRecordError(
      dynamic exception, StackTrace? stack) async {
    if (!_isInitialized) {
      log('_internalRecordError, countly is not initialized',
          logLevel: LogLevel.WARNING);
      return;
    }

    log('_internalRecordError, Exception : ${exception.toString()}');
    if (stack != null) log('\n_internalRecordError, Stack : $stack');

    stack ??= StackTrace.fromString('');
    try {
      unawaited(logException('${exception.toString()}\n\n$stack', true));
    } catch (e) {
      log('Sending crash report to Countly failed: $e');
    }
  }

  /// Enable campaign attribution reporting to Countly.
  /// For iOS use 'recordAttributionID' instead of 'enableAttribution'
  /// Should be call before Countly init
  static Future<String?> enableAttribution() async {
    List<String> args = [];
    final String? result = await _channel.invokeMethod(
        'enableAttribution', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }

  /// set attribution Id for campaign attribution reporting.
  /// Currently implemented for iOS only
  /// For Android just call the enableAttribution to enable campaign attribution.
  static Future<String?> recordAttributionID(String attributionID) async {
    if (!Platform.isIOS) {
      return 'recordAttributionID : To be implemented';
    }
    if (attributionID.isEmpty) {
      String error = 'recordAttributionID, attributionID cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(attributionID);
    final String? result = await _channel.invokeMethod(
        'recordAttributionID', <String, dynamic>{'data': json.encode(args)});
    log(result);
    return result;
  }
}

class CountlyPresentableFeedback {
  CountlyPresentableFeedback(this.widgetId, this.type, this.name);

  final String widgetId;
  final String type;
  final String name;

  static CountlyPresentableFeedback fromJson(dynamic json) {
    return CountlyPresentableFeedback(json['id'], json['type'], json['name']);
  }
}

class FeedbackWidgetsResponse {
  FeedbackWidgetsResponse(this.presentableFeedback, this.error);

  final String? error;
  final List<CountlyPresentableFeedback> presentableFeedback;
}
