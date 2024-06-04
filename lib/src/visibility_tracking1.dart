import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CountlyVisibilityWidget extends StatelessWidget {
  const CountlyVisibilityWidget({required this.child, required this.name, Key? key}) : super(key: key);
  final Widget child;
  final String name;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: GlobalKey(),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        Countly.instance.views.trackWidget(name, visiblePercentage);
      },
      child: child,
    );
  }
}
