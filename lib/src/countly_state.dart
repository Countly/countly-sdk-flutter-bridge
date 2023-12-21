import 'package:flutter/services.dart';
import 'countly_flutter.dart';

class CountlyState {
  CountlyState(this.cly);
  Countly cly;

  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  bool isInitialized = false;

  final channel = const MethodChannel('countly_flutter');
}
