import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/material.dart';

class CountlyVisibilityTracker extends StatefulWidget {
  const CountlyVisibilityTracker({required this.child, required this.name, Key? key}) : super(key: key);
  final Widget child;
  final String name;

  @override
  State<CountlyVisibilityTracker> createState() => _CountlyVisibilityTrackerState();
}

class _CountlyVisibilityTrackerState extends State<CountlyVisibilityTracker> {
  final key = GlobalKey();

  @override
  void initState() {
    super.initState();

    Countly.instance.views.trackWidgetKey(key, widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: key, child: widget.child);
  }
}
