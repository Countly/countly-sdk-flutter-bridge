import 'package:flutter/material.dart';

import 'countly_flutter.dart';
import 'helper/debouncer.dart';

class CountlyScrollTracking extends StatelessWidget {
  CountlyScrollTracking({required this.child, Key? key}) : super(key: key);
  final Widget child;
  final _debouncer = Debouncer(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // _debouncer.run(
        //   () => Countly.instance.views.trackScroll(
        //     notification,
        //     widget.debugName,
        //     context,
        //   ),
        // );
        return false;
      },
      child: child,
    );
  }
}
