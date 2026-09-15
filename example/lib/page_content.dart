import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class ContentPage extends StatefulWidget {
  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final TextEditingController _deviceIdController = TextEditingController();
  String _currentDeviceId = '';

  @override
  void initState() {
    super.initState();
    _fetchDeviceId();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceId() async {
    String? deviceId = await Countly.instance.deviceId.getID();
    if (mounted && deviceId != null) {
      setState(() {
        _currentDeviceId = deviceId;
      });
    }
  }

  void enterContentZone() {
    Countly.instance.content.enterContentZone();
  }

  void exitContentZone() {
    Countly.instance.content.exitContentZone();
  }

  void refreshContentZone() {
    Countly.instance.content.refreshContentZone();
  }

  Future<void> changeDeviceIdAndGiveConsent() async {
    final newId = _deviceIdController.text.trim();
    if (newId.isEmpty) {
      if (mounted) {
        showCountlyToast(context, 'Please enter a Device ID', null);
      }
      return;
    }
    Countly.instance.deviceId.setID(newId);
    Countly.giveAllConsent();
    _deviceIdController.clear();
    await _fetchDeviceId();
    if (mounted) {
      showCountlyToast(context, 'Device ID set & all consent given', null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Content')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device ID info card
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Device ID', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    _currentDeviceId.isEmpty ? 'N/A' : _currentDeviceId,
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Change device ID section
          CountlySection(
            title: 'Change Device ID',
            subtitle: 'Sets a new device ID and gives all consent',
            children: [
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(labelText: 'New Device ID', hintText: 'Enter new device ID'),
              ),
              const SizedBox(height: 8),
              MyButton(text: 'Set ID & Give All Consent', type: CountlyButtonType.filled, onPressed: changeDeviceIdAndGiveConsent),
            ],
          ),
          const SizedBox(height: 16),

          // Content Zones section
          CountlySection(
            title: 'Content Zones',
            children: [
              MyButton(text: 'Enter Content Zone', type: CountlyButtonType.filled, onPressed: enterContentZone),
              MyButton(text: 'Exit Content Zone', type: CountlyButtonType.outlined, onPressed: exitContentZone),
              MyButton(text: 'Refresh Content Zone', type: CountlyButtonType.tonal, onPressed: refreshContentZone),
            ],
          ),
        ],
      ),
    );
  }
}
