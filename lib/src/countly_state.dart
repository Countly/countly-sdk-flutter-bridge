import 'package:flutter/services.dart';
import 'countly_flutter.dart';

class CountlyState {
  CountlyState(this.cly, [this.instanceName]);
  Countly cly;

  /// Name of the instance this state belongs to, "null" for the default instance.
  final String? instanceName;

  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  bool isInitialized = false;

  final channel = const MethodChannel('countly_flutter');

  /// Builds the method channel arguments for a call, tagging it with the instance it is meant for.
  /// Calls for the default instance carry no name, so the native side keeps its existing behaviour.
  /// [String? data]: the JSON encoded positional arguments of the call, if it takes any
  /// [Map<String, dynamic>? extra]: named arguments a few calls use instead of the positional ones
  Map<String, dynamic> arguments([String? data, Map<String, dynamic>? extra]) => <String, dynamic>{
        if (data != null) 'data': data,
        if (instanceName != null) 'instanceName': instanceName,
        ...?extra,
      };

  /// The reason a call can not be made yet, or "null" once the instance is initialized.
  /// Logs the refusal under [tag], so the internals do not each carry the same guard.
  /// [String tag]: the internal the call belongs to, for the log line
  /// [String method]: the name of the call, for the message
  String? requireInit(String tag, String method) {
    if (isInitialized) {
      return null;
    }
    final String message = '"initWithConfig" must be called before "$method"';
    Countly.log('[$tag] $method, $message', logLevel: LogLevel.ERROR);
    return message;
  }
}
