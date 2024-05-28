import 'package:countly_flutter/src/visibility_tracking1.dart';
import 'package:flutter/material.dart';

class ScrollDemo1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
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
                          Text('Column 1'),
                          SizedBox(height: 10),
                          for (int i = 0; i < 15; i++)
                            CountlyVisibilityWidget(
                              name: 'Widget 1 ${i + 1}',
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
                          Text('Column 2'),
                          SizedBox(height: 10),
                          for (int i = 0; i < 15; i++)
                            i % 2 == 0
                                ? Box(count: i + 1, extra: 'NT')
                                : CountlyVisibilityWidget(
                                    name: 'Widget 2 ${i + 1}',
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
                    Text('Column 3'),
                    SizedBox(height: 10),
                    for (int i = 0; i < 15; i++) Box(count: i + 1),
                  ],
                ),
              ),
            ],
          ),
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
