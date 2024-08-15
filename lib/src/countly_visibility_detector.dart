import 'package:flutter/material.dart';

class CountlyVisibilityDectector extends StatefulWidget {
  const CountlyVisibilityDectector({required this.child, Key? key}) : super(key: key);
  final Widget child;

  @override
  State<CountlyVisibilityDectector> createState() => _CountlyVisibilityDectectorState();
}

class _CountlyVisibilityDectectorState extends State<CountlyVisibilityDectector> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print('CountlyVisibilityDectector: App is visible and in the foreground');
        break;
      case AppLifecycleState.paused:
        print('CountlyVisibilityDectector: App is not visible and in the background');
        break;
      case AppLifecycleState.inactive:
        print('CountlyVisibilityDectector: App is inactive (e.g., phone call, lock screen)');
        break;
      case AppLifecycleState.detached:
        print('CountlyVisibilityDectector: App is detached from the view hierarchy');
        break;
      case AppLifecycleState.hidden:
        print('CountlyVisibilityDectector: App is hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
