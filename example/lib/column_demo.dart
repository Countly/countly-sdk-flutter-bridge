import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/src/visibility_tracking1.dart';
import 'package:flutter/material.dart';

class ColumnDemo extends StatefulWidget {
  @override
  State<ColumnDemo> createState() => _ColumnDemoState();
}

class _ColumnDemoState extends State<ColumnDemo> {
  @override
  void initState() {
    super.initState();

    Countly.instance.views.startView('Tab1');
  }

  @override
  void dispose() {
    super.dispose();

    Countly.instance.views.stopViewWithName('Tab1');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueAccent,
                    ),
                  ),
                  margin: const EdgeInsets.all(3.0),
                  padding: const EdgeInsets.all(5.0),
                  height: MediaQuery.of(context).size.height / 2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text('Column A'),
                        SizedBox(height: 10),
                        for (int i = 0; i < 15; i++)
                          CountlyVisibilityWidget(
                            name: 'Tab 1 Column A Widget ${i + 1}',
                            child: Box(count: i + 1),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Text('Space'),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueAccent,
                    ),
                  ),
                  margin: const EdgeInsets.all(3.0),
                  padding: const EdgeInsets.all(5.0),
                  height: MediaQuery.of(context).size.height / 2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text('Column B'),
                        SizedBox(height: 10),
                        for (int i = 0; i < 15; i++)
                          i % 2 == 0
                              ? Box(count: i + 1, extra: 'NT')
                              : CountlyVisibilityWidget(
                                  name: 'Tab 1 Column B Widget ${i + 1}',
                                  child: Box(count: i + 1),
                                ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent,
                ),
              ),
              margin: const EdgeInsets.all(3.0),
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Text('Column C'),
                  SizedBox(height: 10),
                  for (int i = 0; i < 15; i++) Box(count: i + 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Box extends StatelessWidget {
  const Box({required this.count, this.extra = '', Key? key}) : super(key: key);
  final int count;
  final String extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
      margin: const EdgeInsets.all(3.0),
      padding: const EdgeInsets.all(5.0),
      child: Text(
        'Count: $count, $extra',
        textAlign: TextAlign.center,
      ),
    );
  }
}
