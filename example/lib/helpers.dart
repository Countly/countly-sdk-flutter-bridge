import 'package:countly_flutter_example/style.dart';
import 'package:flutter/material.dart';

enum CountlyButtonType { filled, tonal, outlined, text }

// Current button that we use in the app
class MyButton extends StatelessWidget {
  final String _text;
  final CountlyButtonType _type;
  final Color? _color;
  final void Function()? _onPressed;

  MyButton({
    required String text,
    String? color,
    CountlyButtonType type = CountlyButtonType.tonal,
    void Function()? onPressed,
    super.key,
  })  : _text = text,
        _type = type,
        _onPressed = onPressed,
        _color = _resolveColor(color);

  static Color? _resolveColor(String? color) {
    if (color == null) return null;
    return getColor(color)?['button'];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (_type) {
      case CountlyButtonType.filled:
        return FilledButton(
          onPressed: _onPressed,
          style: _color != null ? FilledButton.styleFrom(backgroundColor: _color) : null,
          child: Text(_text, textAlign: TextAlign.center),
        );
      case CountlyButtonType.tonal:
        return FilledButton.tonal(
          onPressed: _onPressed,
          child: Text(_text, textAlign: TextAlign.center),
        );
      case CountlyButtonType.outlined:
        return OutlinedButton(
          onPressed: _onPressed,
          child: Text(_text, textAlign: TextAlign.center),
        );
      case CountlyButtonType.text:
        return TextButton(
          onPressed: _onPressed,
          child: Text(_text, textAlign: TextAlign.center),
        );
    }
  }
}

// Section card that groups related buttons
class CountlySection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const CountlySection({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle()),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: subTitleStyle()),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Sub-section for nested groupings inside a CountlySection
class CountlySubSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const CountlySubSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: subTitleStyle()),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

// Page scaffold with consistent layout for all pages
class CountlyPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> sections;

  const CountlyPageScaffold({
    required this.title,
    required this.sections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) => sections[index],
      ),
    );
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
  return const SizedBox(height: 16);
}

Widget countlySpacerSmall() {
  return const SizedBox(height: 8);
}

Widget countlySubTitle(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: subTitleStyle()),
  );
}

Widget countlyTitle(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: titleStyle()),
  );
}

void showCountlyToast(BuildContext context, String message, Color? color) {
  final snackBar = SnackBar(
    content: Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    duration: const Duration(seconds: 3),
    backgroundColor: color ?? Theme.of(context).colorScheme.primaryContainer,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
