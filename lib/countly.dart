import 'dart:async';

import 'package:flutter/services.dart';

class Countly {
  static const MethodChannel _channel =
      const MethodChannel('countly');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> init(String serverUrl, String appKey, [String deviceId]) async {
    List <String> arg = [];
    arg.add(serverUrl);
    arg.add(appKey);
    if(deviceId != null){
      arg.add(deviceId);
    }
    // print("json");
    // print(json(arg));
    final String result = await _channel.invokeMethod('init', <String, dynamic>{
        'data': json(arg)// '["https://try.count.ly", "0e8a00e8c01395a0af8be0e55da05a404bb23c3e"]',
      });
    print(result);
    return result;
  }

  static String json(List <String> list){
    String j = '[';
    int i = 0;
    list.forEach((v){
      j+= '"' +v.replaceAll('"', '\\"') +'"';
      i++;
      if(list.length != i){
        j+=',';
      }
    });
    j+=']';
    return j;
  }
}
