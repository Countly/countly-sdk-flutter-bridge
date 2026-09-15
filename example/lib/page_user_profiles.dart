import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class UserProfilesPage extends StatefulWidget {
  @override
  State<UserProfilesPage> createState() => _UserProfilesPageState();
}

class _UserProfilesPageState extends State<UserProfilesPage> {
  final TextEditingController _nameController = TextEditingController(text: 'Name of User');
  final TextEditingController _usernameController = TextEditingController(text: 'Username');
  final TextEditingController _emailController = TextEditingController(text: 'User Email');
  final TextEditingController _orgController = TextEditingController(text: 'User Organization');
  final TextEditingController _phoneController = TextEditingController(text: 'User Contact number');
  final TextEditingController _pictureController = TextEditingController(text: 'https://count.ly/images/logos/countly-logo.png');
  final TextEditingController _genderController = TextEditingController(text: 'M');
  final TextEditingController _byearController = TextEditingController(text: '1989');

  // Dynamic custom properties
  final List<_KVEntry> _customProperties = [_KVEntry('Custom Key', 'Custom Value')];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    _phoneController.dispose();
    _pictureController.dispose();
    _genderController.dispose();
    _byearController.dispose();
    for (final entry in _customProperties) {
      entry.dispose();
    }
    super.dispose();
  }

  Map<String, Object> _buildCustomPropertiesMap() {
    final map = <String, Object>{};
    for (final entry in _customProperties) {
      final key = entry.keyController.text.trim();
      final value = entry.valueController.text.trim();
      if (key.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }

  void _addCustomProperty() {
    setState(() {
      _customProperties.add(_KVEntry('', ''));
    });
  }

  void _removeCustomProperty(int index) {
    setState(() {
      _customProperties[index].dispose();
      _customProperties.removeAt(index);
    });
  }

  void setUserData() {
    Map<String, Object> options = {
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'organization': _orgController.text.trim(),
      'phone': _phoneController.text.trim(),
      'picture': _pictureController.text.trim(),
      'picturePath': '',
      'gender': _genderController.text.trim(),
      'byear': _byearController.text.trim(),
    };
    Countly.instance.userProfile.setUserProperties(options);
  }

  void setProperties() {
    Map<String, Object> userProperties = {
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'organization': _orgController.text.trim(),
      'phone': _phoneController.text.trim(),
      'picture': _pictureController.text.trim(),
      'picturePath': '',
      'gender': _genderController.text.trim(),
      'byear': _byearController.text.trim(),
      ..._buildCustomPropertiesMap(),
    };
    Countly.instance.userProfile.setUserProperties(userProperties);
  }

  void setCustomProperties() {
    final props = _buildCustomPropertiesMap();
    Countly.instance.userProfile.setUserProperties(props);
  }

  void increment() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'increment';
    Countly.instance.userProfile.increment(key);
  }

  void incrementBy() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'incrementBy';
    Countly.instance.userProfile.incrementBy(key, 10);
  }

  void multiply() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'multiply';
    Countly.instance.userProfile.multiply(key, 20);
  }

  void saveMax() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'saveMax';
    Countly.instance.userProfile.saveMax(key, 100);
  }

  void saveMin() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'saveMin';
    Countly.instance.userProfile.saveMin(key, 50);
  }

  void setOnce() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'setOnce';
    final value = _customProperties.isNotEmpty ? _customProperties.first.valueController.text.trim() : '200';
    Countly.instance.userProfile.setOnce(key, value);
  }

  void pushUniqueValue() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'pushUniqueValue';
    final value = _customProperties.isNotEmpty ? _customProperties.first.valueController.text.trim() : 'morning';
    Countly.instance.userProfile.pushUnique(key, value);
  }

  void pushValue() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'pushValue';
    final value = _customProperties.isNotEmpty ? _customProperties.first.valueController.text.trim() : 'morning';
    Countly.instance.userProfile.push(key, value);
  }

  void pullValue() {
    final key = _customProperties.isNotEmpty ? _customProperties.first.keyController.text.trim() : 'pushValue';
    final value = _customProperties.isNotEmpty ? _customProperties.first.valueController.text.trim() : 'morning';
    Countly.instance.userProfile.pull(key, value);
  }

  void save() {
    Countly.instance.userProfile.save();
  }

  void clear() {
    Countly.instance.userProfile.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profiles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User data form
          CountlySection(
            title: 'User Data',
            subtitle: 'Edit the fields and use the buttons below',
            children: [
              TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Username')),
              const SizedBox(height: 8),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: _orgController, decoration: InputDecoration(labelText: 'Organization')),
              const SizedBox(height: 8),
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 8),
              TextField(controller: _pictureController, decoration: InputDecoration(labelText: 'Picture URL')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _genderController, decoration: InputDecoration(labelText: 'Gender'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _byearController, decoration: InputDecoration(labelText: 'Birth Year'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              MyButton(text: 'Send User Data', type: CountlyButtonType.filled, onPressed: setUserData),
              MyButton(text: 'Set All Properties (user + custom)', type: CountlyButtonType.tonal, onPressed: setProperties),
            ],
          ),
          const SizedBox(height: 16),

          // Custom properties with dynamic add/remove
          CountlySection(
            title: 'Custom Properties',
            subtitle: 'Add key-value pairs for custom user properties',
            children: [
              for (int i = 0; i < _customProperties.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _customProperties[i].keyController, decoration: InputDecoration(labelText: 'Key'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _customProperties[i].valueController, decoration: InputDecoration(labelText: 'Value'))),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: _customProperties.length > 1 ? () => _removeCustomProperty(i) : null,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCustomProperty,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Property'),
                ),
              ),
              const SizedBox(height: 4),
              MyButton(text: 'Set Custom Properties Only', type: CountlyButtonType.tonal, onPressed: setCustomProperties),
            ],
          ),
          const SizedBox(height: 16),

          // Modifiers
          CountlySection(
            title: 'Modifiers',
            subtitle: 'Uses the first custom property key/value above',
            children: [
              MyButton(text: 'Increment', type: CountlyButtonType.tonal, onPressed: increment),
              MyButton(text: 'Increment By 10', type: CountlyButtonType.tonal, onPressed: incrementBy),
              MyButton(text: 'Multiply By 20', type: CountlyButtonType.tonal, onPressed: multiply),
              MyButton(text: 'Save Max (100)', type: CountlyButtonType.tonal, onPressed: saveMax),
              MyButton(text: 'Save Min (50)', type: CountlyButtonType.tonal, onPressed: saveMin),
              MyButton(text: 'Set Once', type: CountlyButtonType.tonal, onPressed: setOnce),
              MyButton(text: 'Push Unique Value', type: CountlyButtonType.tonal, onPressed: pushUniqueValue),
              MyButton(text: 'Push Value', type: CountlyButtonType.tonal, onPressed: pushValue),
              MyButton(text: 'Pull Value', type: CountlyButtonType.tonal, onPressed: pullValue),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          CountlySection(
            title: 'Actions',
            children: [
              MyButton(text: 'Save', type: CountlyButtonType.filled, onPressed: save),
              MyButton(text: 'Clear', type: CountlyButtonType.outlined, onPressed: clear),
            ],
          ),
        ],
      ),
    );
  }
}

class _KVEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _KVEntry(String key, String value)
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
