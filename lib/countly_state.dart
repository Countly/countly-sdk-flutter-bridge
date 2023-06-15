import 'package:flutter/services.dart';

class CountlyState {
  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  bool isInitialized = false;

  final channel = const MethodChannel('countly_flutter');
}
