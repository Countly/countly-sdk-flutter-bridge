import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io' show Platform;

class Countly {
  static const MethodChannel _channel =
  const MethodChannel('countly');


  // static variable
  static bool isDebug = true;
  static Map<String, Object> messagingMode = {"DEVELOPMENT": 1, "PRODUCTION": 0, "ADHOC": 2};


  static Future<String> init(String serverUrl, String appKey, [String deviceId]) async {
    if (Platform.isAndroid) {
        messagingMode = {"DEVELOPMENT": 2, "PRODUCTION": 0};
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


  static Future<String> sendEvent( Map<String, Object> options) async {
    if(isDebug){
      print('sendEvent');
    }
    List <String> args = [];
    var eventType = "event"; //event, eventWithSum, eventWithSegment, eventWithSumSegment
    var segment = {};

    if(options["sum"] != null)
        eventType = "eventWithSum";
    if(options["segment"] != null)
        eventType = "eventWithSegment";
    if((options["segment"] != null) && (options["sum"] != null))
        eventType = "eventWithSumSegment";

    args.add(eventType);

    if(options["key"] != null)
        args.add(options["key"].toString());
    if(options["count"] != null){
        args.add(options["count"].toString());
    }else{
        args.add("1");
    }
    if(options["sum"] != null){
        args.add(options["sum"].toString());
    }

    if(options["segment"] != null){
        segment = options["segment"];
        segment.forEach((k, v){
          args.add(k.toString());
          args.add(v.toString());
        });
    }

    final String result = await _channel.invokeMethod('event', <String, dynamic>{
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
///
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
static Future<String> sendPushToken(Map<String, Object> options) async {
    List <String> args = [];
    // args.add(options["token"] || "");
    // args.add(options["messagingMode"] || Countly.messagingMode["PRODUCTION"]);

    final String result = await _channel.invokeMethod('sendPushToken', <String, dynamic>{
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

static Future<String> setOptionalParametersForInitialization(Map<String, Object> options) async {
    List <String> args = [];
    String latitude = options["latitude"];
    String ipAddress = options["ipAddress"];
    options["latitude"] = options["latitude"].toString();
    options["longitude"] = options["longitude"].toString();
    // if(options["latitude && !options.latitude"].match('\\.')){
    //     options["latitude"] =   + ".00";
    // }
    // if(optionslongitude && !options["longitude"].match('\\.')){
    //     options["longitude"] = latitude + ".00";
    // }
    if(options["city"] == null){
      options["city"] = "";
    }
    if(options["country"] == null){
      options["country"] = "";
    }
    if(options["latitude"] == null){
      options["latitude"] = "";
    }
    if(options["longitude"] == null){
      options["longitude"] = "";
    }
    if(options["ipAddress"] == null){
      options["ipAddress"] = "";
    }
    args.add(options["city"]);
    args.add(options["country"]);
    args.add(options["latitude"]);
    args.add(options["longitude"]);
    args.add(options["ipAddress"]);
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

static Future<String> addCrashLog(String newDeviceID) async {
    List <String> args = [];
    args.add(newDeviceID);
    final String result = await _channel.invokeMethod('addCrashLog', <String, dynamic>{
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
static Future<String> giveConsent(List <String> consent) async {
  List <String> args = consent;
  final String result = await _channel.invokeMethod('giveConsent', <String, dynamic>{
      'data': json.encode(args)
  });
  if(isDebug){
    print(result);
  }
  return result;
}
static Future<String> removeConsent(List <String> consent) async {
  List <String> args = consent;
  
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

  static Future<String> setRemoteConfigAutomaticDownload(Function onSuccess) async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('setRemoteConfigAutomaticDownload', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> remoteConfigUpdate(Function onSuccess, Function onError) async {
    List <String> args = [];
    
    final String result = await _channel.invokeMethod('remoteConfigUpdate', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> updateRemoteConfigForKeysOnly(Object keys, Function onSuccess, Function onError) async {
    List <String> args = [];
    
    final String result = await _channel.invokeMethod('updateRemoteConfigForKeysOnly', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> updateRemoteConfigExceptKeys(Object keys, Function onSuccess, Function onError) async {
    List <String> args = [];
    
    final String result = await _channel.invokeMethod('updateRemoteConfigExceptKeys', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> remoteConfigClearValues(Function onSuccess, Function onError) async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('remoteConfigClearValues', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> getRemoteConfigValueForKey(String key, Function onSuccess, Function onError) async {
    List <String> args = [];
    final String result = await _channel.invokeMethod('getRemoteConfigValueForKey', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> sendRating(int sendRating) async {
    List <String> args = [];
    args.add(sendRating.toString());
    final String result = await _channel.invokeMethod('sendRating', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> askForStarRating(callback) async {
    List <String> args = [];
    // Countly.rating.create();
    // Countly.rating.set(0);
    // Countly.rating.callback = callback;
    // query('countly-rating-modal').classList.add('open');
    final String result = await _channel.invokeMethod('askForStarRating', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> askForFeedback(callback) async {
    List <String> args = [];
    // Countly.rating.create();
    // Countly.rating.set(0);
    // Countly.rating.callback = callback;
    // query('countly-rating-modal').classList.add('open');
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
        // options = {"eventName": options};
    var eventType = "event"; //event, eventWithSum, eventWithSegment, eventWithSumSegment
    var segment = {};

    if(options["sum"] != null)
        eventType = "eventWithSum";
    if(options["segment"] != null)
        eventType = "eventWithSegment";
    if((options["segment"] != null) && (options["sum"] != null))
        eventType = "eventWithSumSegment";

    args.add(eventType);

    if(options["key"] != null)
        args.add(options["key"].toString());
    if(options["count"] != null){
        args.add(options["count"].toString());
    }else{
        args.add("1");
    }
    if(options["sum"] != null){
        args.add(options["sum"].toString());
    }

    if(options["segment"] != null){
        segment = options["segment"];
        segment.forEach((k, v){
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
  //  Countly.isCrashReportingEnabled = true;
    final String result = await _channel.invokeMethod('enableCrashReporting', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> logException() async {
    List <String> args = [];
  
    final String result = await _channel.invokeMethod('logException', <String, dynamic>{
        'data': json.encode(args)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  // static Future<String> sendEvent(String serverUrl, String appKey, [String deviceId]) async {
  //   List <String> args = [];
  //   args.add(serverUrl);
  //   args.add(appKey);
  //   if(deviceId != null){
  //     args.add(deviceId);
  //   }

  //   final String result = await _channel.invokeMethod('event', <String, dynamic>{
  //       'data': json.encode(args)
  //   });
  //   if(isDebug){
  //     print(result);
  //   }
  //   return result;
  // }

  // static String toJSON(List <String> list){
  //   String j = '[';
  //   int i = 0;
  //   list.forEach((v){
  //     j+= '"' +v.replaceAll('"', '\\"') +'"';
  //     i++;
  //     if(list.length != i){
  //       j+=',';
  //     }
  //   });
  //   j+=']';
  //   return j;
  // }
}
