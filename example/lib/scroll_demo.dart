import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class ScrollDemo extends StatelessWidget {
  const ScrollDemo();

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
