import 'package:countly_flutter/src/countly_flutter.dart';
import 'package:flutter/services.dart';

class CountlyState {
  CountlyState(this.cly);
  Countly cly;

  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  bool isInitialized = false;

  final channel = const MethodChannel('countly_flutter');
}
