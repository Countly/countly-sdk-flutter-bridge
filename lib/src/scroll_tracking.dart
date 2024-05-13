import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/material.dart';

class CountlyScrollTracking extends StatelessWidget {
  const CountlyScrollTracking({required this.child, Key? key}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: Countly.instance.views.trackScroll,
      child: child,
    );
  }
}
