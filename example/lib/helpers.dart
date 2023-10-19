import 'package:countly_flutter_example/style.dart';
import 'package:flutter/material.dart';

// Current button that we use in the app
class MyButton extends StatelessWidget {
  final String _text;
  late final Color? _button;
  late final Color? _textC;
  final void Function()? _onPressed;

  MyButton({
    required String text,
    String? color,
    void Function()? onPressed,
    Key? key,
  })  : _text = text,
        _onPressed = onPressed,
        super(key: key) {
    Map<String, Color>? tColor;
    tColor = getColor(color);
    tColor ??= theColor['default'];
    _button = tColor?['button'];
    _textC = tColor?['text'];
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _button, padding: const EdgeInsets.all(10.0), minimumSize: const Size(double.infinity, 36)), onPressed: _onPressed, child: Text(_text, style: TextStyle(color: _textC), textAlign: TextAlign.center));
  }
}

// Helper function to navigate to a page
void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

Widget countlySpacer() {
  return SizedBox(height: 20);
}

Widget countlySpacerSmall() {
  return SizedBox(height: 10);
}

Widget countlySubTitle(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text('-' + text, style: subTitleStyle()),
  );
}

Widget countlyTitle(String text) {
  return Text(text, style: titleStyle());
}
