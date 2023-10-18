import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class SessionsPage extends StatelessWidget {
// Automatic sessions are handled by the underlying native SDKs and enabled by default.
// These are manual session calls. You must enable manual session handling in your Countly Config first.
  void beginSession() {
    Countly.instance.sessions.beginSession();
  }

  void updateSession() {
    Countly.instance.sessions.updateSession();
  }

  void endSession() {
    Countly.instance.sessions.endSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Begin Session', color: 'green', onPressed: beginSession),
            MyButton(text: 'Update Session', color: 'yellow', onPressed: updateSession),
            MyButton(text: 'End Session', color: 'orange', onPressed: endSession),
          ],
        )),
      ),
    );
  }
}
