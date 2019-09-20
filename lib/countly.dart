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
    print(arg.toString());
    final String result = await _channel.invokeMethod('init', <String, dynamic>{
        'data': arg.toString(),
      });
    print(result);
    return result;
  }
}
