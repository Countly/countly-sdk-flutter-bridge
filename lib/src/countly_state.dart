import 'package:flutter/services.dart';
import 'countly_flutter.dart';

class CountlyState {
  CountlyState(this.cly);
  Countly cly;

  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  bool isInitialized = false;

  /// Completes when the "initWithConfig" call that waits for the platform finishes, or null when none waits.
  Future<void>? pendingInit;

  final channel = const MethodChannel('countly_flutter');

  /// Asks the platform whether the native SDK is initialized, which another Flutter engine may have
  /// done. Unlike [Countly.isInitialized] it leaves [isInitialized] alone, so the answer cannot undo
  /// an init of this engine or stop a later "initWithConfig" from registering its callbacks.
  Future<bool> isNativeInitialized() async {
    final String? result = await channel.invokeMethod('isInitialized');
    return result == 'true';
  }
}
