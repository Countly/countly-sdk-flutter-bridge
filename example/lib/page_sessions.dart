import 'package:countly_flutter_np/countly_flutter.dart';
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
    return CountlyPageScaffold(
      title: 'Sessions',
      sections: [
        CountlySection(
          title: 'Manual Session Control',
          subtitle: 'Enable manual session handling in config first',
          children: [
            MyButton(text: 'Begin Session', type: CountlyButtonType.filled, onPressed: beginSession),
            MyButton(text: 'Update Session', type: CountlyButtonType.tonal, onPressed: updateSession),
            MyButton(text: 'End Session', type: CountlyButtonType.outlined, onPressed: endSession),
          ],
        ),
      ],
    );
  }
}
