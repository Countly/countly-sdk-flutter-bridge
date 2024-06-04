import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/src/visibility_tracking1.dart';
import 'package:countly_flutter_example/column_demo.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:countly_flutter_example/scroll_demo.dart';
import 'package:flutter/material.dart';

class TabBarDemo extends StatefulWidget {
  const TabBarDemo();

  @override
  State<TabBarDemo> createState() => _TabBarDemoState();
}

class _TabBarDemoState extends State<TabBarDemo> {
  @override
  void initState() {
    super.initState();

    Countly.instance.views.startView('TabBarDemo');
  }

  @override
  void dispose() {
    super.dispose();

    Countly.instance.views.stopViewWithName('TabBarDemo');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text('Tab 1')),
              Tab(icon: Text('Tab 2')),
              Tab(icon: Text('Tab 3')),
            ],
          ),
          title: const Text('Tabs Demo'),
        ),
        body: TabBarView(
          children: [
            ColumnDemo(),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  children: [
                    for (int i = 0; i < 30; i++)
                      MyButton(
                        text: 'Button $i',
                        color: 'green',
                        onPressed: () {},
                      ),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  children: [
                    for (int i = 0; i < 30; i++)
                      CountlyVisibilityWidget(
                        name: 'Tab 3 Widget 1 ${i + 1}',
                        child: MyButton(
                          text: 'Button $i',
                          color: 'green',
                          onPressed: () {
                            if (i == 0) {
                              navigateToPage(context, ScrollDemo());
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
