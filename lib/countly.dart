import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io' show Platform;

class Countly {
  static const MethodChannel _channel =
  const MethodChannel('countly');


  // static variable
  static bool isDebug = false;
  static Map<String, Object> messagingMode = {"DEVELOPMENT": 1, "PRODUCTION": 0, "ADHOC": 2};


  static Future<String> init(String serverUrl, String appKey, [String deviceId]) async {
    if (Platform.isAndroid) {
        messagingMode = {"DEVELOPMENT": 2, "PRODUCTION": 0};
    }
    List <String> arg = [];
    arg.add(serverUrl);
    arg.add(appKey);
    if(deviceId != null){
      arg.add(deviceId);
    }

    final String result = await _channel.invokeMethod('init', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }


  static Future<String> sendEvent( Map<String, Object> options) async {
    List <String> arg = [];
    var args = [];
    var eventType = "event"; //event, eventWithSum, eventWithSegment, eventWithSumSegment
    var segments = {};

    if(options["eventSum"])
        eventType = "eventWithSum";
    if(options["segments"])
        eventType = "eventWithSegment";
    if(options["segments"] && options["eventSum"])
        eventType = "eventWithSumSegment";

    args.add(eventType);

    if(options["key"])
        args.add(options["key"].toString());
    if(options["eventCount"]){
        args.add(options["eventCount"].toString());
    }else{
        args.add("1");
    }
    if(options["eventSum"]){
        args.add(options["eventSum"].toString());
    }

    if(options["segments"]){
        segments = options["segments"];
    }
    for (var event in ["segments"]) {
        args.add(event);
        args.add(segments[event]);
    }

    final String result = await _channel.invokeMethod('event', <String, dynamic>{
        'data': json.encode(arg)
      });
    if(isDebug){
      print(result);
    }
    return result;
  }


  ////// 001
  static Future<String> recordView(String view) async {
    List <String> arg = [];
    arg.add(view);
    final String result = await _channel.invokeMethod('recordView', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
///
static Future<String> setUserData(Map<String, Object> options) async {
    List <String> arg = [];
     var args = [];
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


    final String result = await _channel.invokeMethod('setUserData', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
static Future<String> sendPushToken(Map<String, Object> options) async {
    List <String> arg = [];
    // arg.add(options["token"] || "");
    // arg.add(options["messagingMode"] || Countly.messagingMode["PRODUCTION"]);

    final String result = await _channel.invokeMethod('sendPushToken', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }


static Future<String> start() async {
    List <String> arg = [];
    final String result = await _channel.invokeMethod('start', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> stop() async {
    List <String> arg = [];
    final String result = await _channel.invokeMethod('stop', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

static Future<String> setOptionalParametersForInitialization(Map<String, Object> options) async {
    List <String> arg = [];
     var args = [];
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
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

static Future<String> changeDeviceId(String newDeviceID ,bool onServer) async {
    List <String> arg = [];
    String onServerString;
    if(onServer == false){
        onServerString = "0";
    }else{
        onServerString = "1";
    }
    newDeviceID = newDeviceID.toString();
    arg.add(newDeviceID);
    arg.add(onServerString);
    final String result = await _channel.invokeMethod('changeDeviceId', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

static Future<String> addCrashLog(String newDeviceID) async {
    List <String> arg = [];
    arg.add(newDeviceID);
    final String result = await _channel.invokeMethod('addCrashLog', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

static Future<String> enableParameterTamperingProtection(String salt) async {
    List <String> arg = [];
    arg.add(salt);
    final String result = await _channel.invokeMethod('enableParameterTamperingProtection', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
static Future<String> setProperty(String keyName , String keyValue) async {
    List <String> arg = [];
    arg.add(keyName);
    arg.add(keyValue);
    final String result = await _channel.invokeMethod('setProperty', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> increment(String keyName) async {
    List <String> arg = [];
    arg.add(keyName);
    final String result = await _channel.invokeMethod('increment', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> incrementBy(String keyName, int keyIncrement) async {
    List <String> arg = [];
    arg.add(keyName);
    arg.add(keyIncrement.toString());
    final String result = await _channel.invokeMethod('incrementBy', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> multiply(String keyName, int multiplyValue) async {
    List <String> arg = [];
    arg.add(keyName);
    arg.add(multiplyValue.toString());
    final String result = await _channel.invokeMethod('multiply', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> saveMax(String keyName, int saveMax) async {
    List <String> arg = [];
    arg.add(keyName);
    arg.add(saveMax.toString());
    final String result = await _channel.invokeMethod('saveMax', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
static Future<String> saveMin(String keyName, int saveMin) async {
    List <String> arg = [];
    arg.add(keyName);
    arg.add(saveMin.toString());
    final String result = await _channel.invokeMethod('saveMin', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
static Future<String> setOnce(String keyName, int setOnce) async {
    List <String> arg = [];
    arg.add(keyName);
    arg.add(setOnce.toString());
    final String result = await _channel.invokeMethod('setOnce', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> sendRating(int sendRating) async {
    List <String> arg = [];
    arg.add(sendRating.toString());
    final String result = await _channel.invokeMethod('sendRating', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }
  static Future<String> askForStarRating(callback) async {
    List <String> arg = [];
    // Countly.rating.create();
    // Countly.rating.set(0);
    // Countly.rating.callback = callback;
    // query('countly-rating-modal').classList.add('open');
    final String result = await _channel.invokeMethod('askForStarRating', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  static Future<String> startEvent(String key) async {
    List <String> arg = [];
    arg.add(key);
    final String result = await _channel.invokeMethod('startEvent', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

  // static Future<String> sendEvent(String serverUrl, String appKey, [String deviceId]) async {
  //   List <String> arg = [];
  //   arg.add(serverUrl);
  //   arg.add(appKey);
  //   if(deviceId != null){
  //     arg.add(deviceId);
  //   }

  //   final String result = await _channel.invokeMethod('event', <String, dynamic>{
  //       'data': json.encode(arg)
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
