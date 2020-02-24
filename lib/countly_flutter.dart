import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io' show Platform;

class Countly {
  static const MethodChannel _channel =
  const MethodChannel('countly_flutter');


  // static variable
  static bool isDebug = false;
  static bool enableCrashReportingFlag = false;
  static Map<String, Object> messagingMode = {"TEST": "1", "PRODUCTION": "0", "ADHOC": "2"};


  static Future<String> init(String serverUrl, String appKey, [String deviceId]) async {
    if (Platform.isAndroid) {
      messagingMode = {"TEST": "2", "PRODUCTION": "0"};
    }
    List <String> args = [];
    args.add(serverUrl);
    args.add(appKey);
    if(deviceId != null){
      args.add(deviceId);
    }

    final String result = await _channel.invokeMethod('init', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }


  static Future<String> recordEvent( Map<String, Object> options) async {
    List <String> args = [];
    var segmentation = {};

    if(options["key"] == null){
      options["key"] = "default";
    }
    args.add(options["key"].toString());

    if(options["count"] == null){
      options["count"] = 1;
    }
    args.add(options["count"].toString());

    if(options["sum"] == null){
      options["sum"] = "0";
    }
    args.add(options["sum"].toString());

    if(options["duration"] == null){
      options["duration"] = "0";
    }
    args.add(options["duration"].toString());

    if(options["segmentation"] != null){
      segmentation = options["segmentation"];
      segmentation.forEach((k, v){
        args.add(k.toString());
        args.add(v.toString());
      });
    }

    final String result = await _channel.invokeMethod('recordEvent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(json.encode(args));
      print(result);
    }
    return result;
  }

  ////// 001
  static Future<String> recordView(String view) async {
    List <String> args = [];
    args.add(view);
    final String result = await _channel.invokeMethod('recordView', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> setUserData(Map<String, Object> options) async {
    List <String> args = [];
    if(options["name"] == null){
      options["name"] = "";
    }
    if(options["username"] == null){
      options["username"] = "";
    }
    if(options["email"] == null){
      options["email"] = "";
    }
    if(options["organization"] == null){
      options["organization"] = "";
    }
    if(options["phone"] == null){
      options["phone"] = "";
    }
    if(options["picture"] == null){
      options["picture"] = "";
    }
    if(options["picturePath"] == null){
      options["picturePath"] = "";
    }
    if(options["gender"] == null){
      options["gender"] = "";
    }
    if(options["byear"] == null){
      options["byear"] = "0";
    }

    args.add(options["name"]);
    args.add(options["username"]);
    args.add(options["email"]);
    args.add(options["organization"]);
    args.add(options["phone"]);
    args.add(options["picture"]);
    args.add(options["picturePath"]);
    args.add(options["gender"]);
    args.add(options["byear"]);


    final String result = await _channel.invokeMethod('setuserdata', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> askForNotificationPermission() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('askForNotificationPermission', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> pushTokenType(String tokenType) async {
    List <String> args = [];
    args.add(tokenType);
    final String result = await _channel.invokeMethod('pushTokenType', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> start() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('start', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> manualSessionHandling() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('manualSessionHandling', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> stop() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('stop', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> updateSessionPeriod() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('updateSessionPeriod', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> eventSendThreshold() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('updateSessionPeriod', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> storedRequestsLimit() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('storedRequestsLimit', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> setOptionalParametersForInitialization(Map<String, Object> options) async {
    List <String> args = [];

    String city = options["city"];
    String country = options["country"];
    String latitude = options["latitude"];
    String longitude = options["longitude"];
    String ipAddress = options["ipAddress"];

    if(city == null){
      city = "";
    }
    if(country == null){
      country = "";
    }
    if(latitude == null){
      latitude = "0.00";
    }
    if(longitude == null){
      longitude = "0.00";
    }
    if(ipAddress == null){
      ipAddress = "0.0.0.0";
    }

    if(!latitude.contains(".")){
        latitude =  latitude + ".00";
    }
    if(!latitude.contains(".")){
        latitude =  latitude + ".00";
    }

    args.add(city);
    args.add(country);
    args.add(latitude);
    args.add(longitude);
    args.add(ipAddress);

    final String result = await _channel.invokeMethod('setOptionalParametersForInitialization', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> changeDeviceId(String newDeviceID ,bool onServer) async {
    List <String> args = [];
    String onServerString;
    if(onServer == false){
        onServerString = "0";
    }else{
        onServerString = "1";
    }
    newDeviceID = newDeviceID.toString();
    args.add(newDeviceID);
    args.add(onServerString);
    final String result = await _channel.invokeMethod('changeDeviceId', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> addCrashLog(String logs) async {
    List <String> args = [];
    args.add(logs);
    final String result = await _channel.invokeMethod('addCrashLog', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> setLoggingEnabled(bool flag) async {
    List <String> args = [];
    isDebug = flag;
    args.add(flag.toString());
    final String result = await _channel.invokeMethod('setLoggingEnabled', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> enableParameterTamperingProtection(String salt) async {
    List <String> args = [];
    args.add(salt);
    final String result = await _channel.invokeMethod('enableParameterTamperingProtection', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> setHttpPostForced(bool isEnabled) async {
    List <String> args = [];
    args.add(isEnabled.toString());
    final String result = await _channel.invokeMethod('setHttpPostForced', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> setLocation(String latitude, String longitude) async {
    List <String> args = [];
    args.add(latitude);
    args.add(longitude);
    final String result = await _channel.invokeMethod('setLocation', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> setProperty(String keyName , String keyValue) async {
    List <String> args = [];
    args.add(keyName);
    args.add(keyValue);
    final String result = await _channel.invokeMethod('userData_setProperty', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> increment(String keyName) async {
    List <String> args = [];
    args.add(keyName);
    final String result = await _channel.invokeMethod('userData_increment', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> incrementBy(String keyName, int keyIncrement) async {
    List <String> args = [];
    args.add(keyName);
    args.add(keyIncrement.toString());
    final String result = await _channel.invokeMethod('userData_incrementBy', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> multiply(String keyName, int multiplyValue) async {
    List <String> args = [];
    args.add(keyName);
    args.add(multiplyValue.toString());
    final String result = await _channel.invokeMethod('userData_multiply', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> saveMax(String keyName, int saveMax) async {
    List <String> args = [];
    args.add(keyName);
    args.add(saveMax.toString());
    final String result = await _channel.invokeMethod('userData_saveMax', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> saveMin(String keyName, int saveMin) async {
    List <String> args = [];
    args.add(keyName);
    args.add(saveMin.toString());
    final String result = await _channel.invokeMethod('userData_saveMin', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> setOnce(String keyName, int setOnce) async {
    List <String> args = [];
    args.add(keyName);
    args.add(setOnce.toString());
    final String result = await _channel.invokeMethod('userData_setOnce', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> pushUniqueValue(String type, String pushUniqueValue) async {
    List <String> args = [];
    args.add(type);
    args.add(pushUniqueValue);
    final String result = await _channel.invokeMethod('userData_pushUniqueValue', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> pushValue(String type, String pushValue) async {
    List <String> args = [];
    args.add(type);
    args.add(pushValue);
    final String result = await _channel.invokeMethod('userData_pushValue', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> pullValue(String type, String pullValue) async {
    List <String> args = [];
    args.add(type);
    args.add(pullValue);
    final String result = await _channel.invokeMethod('userData_pullValue', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  //setRequiresConsent
  static Future<String> setRequiresConsent(bool flag) async {
    List <String> args = [];
    args.add(flag.toString());
    final String result = await _channel.invokeMethod('setRequiresConsent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> giveConsent(List <String> consents) async {
    List <String> args = consents;
    final String result = await _channel.invokeMethod('giveConsent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> removeConsent(List <String> consents) async {
    List <String> args = consents;
    final String result = await _channel.invokeMethod('removeConsent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> giveAllConsent() async {
    List <String> args = [];

    final String result = await _channel.invokeMethod('giveAllConsent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> removeAllConsent() async {
    List <String> args = [];

    final String result = await _channel.invokeMethod('removeAllConsent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> setRemoteConfigAutomaticDownload(Function callback) async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('setRemoteConfigAutomaticDownload', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    callback(result);
    return result;
  }
  static Future<String> remoteConfigUpdate(Function callback) async {
    List <String> args = [];

    final String result = await _channel.invokeMethod('remoteConfigUpdate', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    callback(result);
    return result;
  }
  static Future<String> updateRemoteConfigForKeysOnly(List<String> args, Function callback) async {
    final String result = await _channel.invokeMethod('updateRemoteConfigForKeysOnly', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    callback(result);
    return result;
  }
  static Future<String> updateRemoteConfigExceptKeys(Object keys, Function callback) async {
    List <String> args = [];

    final String result = await _channel.invokeMethod('updateRemoteConfigExceptKeys', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    callback(result);
    return result;
  }
  static Future<String> remoteConfigClearValues(Function callback) async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('remoteConfigClearValues', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    callback(result);
    return result;
  }
  static Future<String> getRemoteConfigValueForKey(String key, Function callback) async {
    List <String> args = [];
    args.add(key);
    final String result = await _channel.invokeMethod('getRemoteConfigValueForKey', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    callback(result);
    return result;
  }
  static Future<String> askForStarRating() async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('askForStarRating', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> askForFeedback(String widgetId, String closeButtonText) async {
    List <String> args = [];
    args.add(widgetId);
    args.add(closeButtonText);
    final String result = await _channel.invokeMethod('askForFeedback', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> startEvent(String key) async {
    List <String> args = [];
    args.add(key);
    final String result = await _channel.invokeMethod('startEvent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> endEvent(Map<String, Object> options) async {
    List <String> args = [];
    var segmentation = {};

    if(options["key"] == null){
      options["key"] = "default";
    }
    args.add(options["key"].toString());

    if(options["count"] == null){
      options["count"] = 1;
    }
    args.add(options["count"].toString());

    if(options["sum"] == null){
      options["sum"] = "0";
    }
    args.add(options["sum"].toString());

    if(options["segmentation"] != null){
      segmentation = options["segmentation"];
      segmentation.forEach((k, v){
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    final String result = await _channel.invokeMethod('endEvent', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> enableCrashReporting() async {
    List <String> args = [];
    enableCrashReportingFlag = true;
    final String result = await _channel.invokeMethod('enableCrashReporting', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> logException(String execption,bool nonfatal, Map<String, Object> segmentation) async {
    List <String> args = [];

    args.add(execption);
    args.add(nonfatal.toString());
    if(segmentation != null){
      segmentation.forEach((k, v){
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    final String result = await _channel.invokeMethod('logException', <String, dynamic>{
      'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
}
