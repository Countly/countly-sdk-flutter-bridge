import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:convert';

class Countly {
  static const MethodChannel _channel =
      const MethodChannel('countly');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  static bool isDebug = false;
  static Future<String> init(String serverUrl, String appKey, [String deviceId]) async {
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

  static Future<String> sendEvent(String serverUrl, String appKey, [String deviceId]) async {
    List <String> arg = [];
    arg.add(serverUrl);
    arg.add(appKey);
    if(deviceId != null){
      arg.add(deviceId);
    }

    final String result = await _channel.invokeMethod('event', <String, dynamic>{
        'data': json.encode(arg)
    });
    if(isDebug){
      print(result);
    }
    return result;
  }

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
