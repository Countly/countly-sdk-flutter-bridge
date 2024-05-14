import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class ScrollDemo extends StatefulWidget {
  const ScrollDemo();

  @override
  State<ScrollDemo> createState() => _ScrollDemoState();
}

class _ScrollDemoState extends State<ScrollDemo> {
  final key = new GlobalKey();
  final key1 = new GlobalKey();

  @override
  void initState() {
    super.initState();

    // First method
    Countly.instance.views.trackWidgetKey(key, 'Widget 0');
    Countly.instance.views.trackWidgetKey(key1, 'Widget 29');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              for (int i = 0; i < 30; i++)
                MyButton(
                  key: i == 0
                      ? key
                      : i == 29
                          ? key1
                          : null,
                  text: 'Button $i',
                  color: 'green',
                  onPressed: () {},
                ),
            ],
          ),
        ),
      ),
    );
  }
}
