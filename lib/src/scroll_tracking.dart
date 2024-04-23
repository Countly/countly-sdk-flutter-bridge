import 'package:flutter/material.dart';

class CountlyScrollTracking extends StatelessWidget {
  const CountlyScrollTracking({required this.child, Key? key}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        print('Pixels: ${metrics.pixels}, total: ${metrics.extentTotal}, inside: ${metrics.extentInside}, before: ${metrics.extentBefore}, after: ${metrics.extentAfter}');

        // locally store it in views
        // Countly.instance.views.addScrollTrackingInfo(metrics);

        return false;
      },
      child: child,
    );
  }
}
