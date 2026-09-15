import 'dart:async';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class EventsPage extends StatefulWidget {
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final TextEditingController _eventKeyController = TextEditingController(text: 'My Event');
  final TextEditingController _countController = TextEditingController(text: '1');
  final TextEditingController _sumController = TextEditingController(text: '0.99');

  // Dynamic segmentation entries
  final List<_KVEntry> _segmentations = [_KVEntry('Country', 'Turkey')];

  @override
  void dispose() {
    _eventKeyController.dispose();
    _countController.dispose();
    _sumController.dispose();
    for (final entry in _segmentations) {
      entry.dispose();
    }
    super.dispose();
  }

  String get _eventKey => _eventKeyController.text.trim().isEmpty ? 'My Event' : _eventKeyController.text.trim();
  int get _count => int.tryParse(_countController.text.trim()) ?? 1;
  String get _sum => _sumController.text.trim().isEmpty ? '0.99' : _sumController.text.trim();

  Map<String, String> get _segmentation {
    final map = <String, String>{};
    for (final entry in _segmentations) {
      final key = entry.keyController.text.trim();
      final value = entry.valueController.text.trim();
      if (key.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }

  void _addSegmentation() {
    setState(() {
      _segmentations.add(_KVEntry('', ''));
    });
  }

  void _removeSegmentation(int index) {
    setState(() {
      _segmentations[index].dispose();
      _segmentations.removeAt(index);
    });
  }

  void basicEvent() {
    Countly.recordEvent({'key': _eventKey, 'count': _count});
  }

  void eventWithSum() {
    Countly.recordEvent({'key': _eventKey, 'count': _count, 'sum': _sum});
  }

  void eventWithSegment() {
    var event = {'key': _eventKey, 'count': _count};
    event['segmentation'] = _segmentation;
    Countly.recordEvent(event);
  }

  void eventWithSumSegment() {
    var event = {'key': _eventKey, 'count': _count, 'sum': _sum};
    event['segmentation'] = _segmentation;
    Countly.recordEvent(event);
  }

  void endEventBasic() {
    Countly.startEvent(_eventKey);
    Timer(const Duration(seconds: 5), () {
      Countly.endEvent({'key': _eventKey});
    });
  }

  void endEventWithSum() {
    final key = '$_eventKey With Sum';
    Countly.startEvent(key);
    Timer(const Duration(seconds: 5), () {
      Countly.endEvent({'key': key, 'sum': _sum});
    });
  }

  void endEventWithSegment() {
    final key = '$_eventKey With Segment';
    Countly.startEvent(key);
    Timer(const Duration(seconds: 5), () {
      var event = {'key': key, 'count': _count};
      event['segmentation'] = _segmentation;
      Countly.endEvent(event);
    });
  }

  void endEventWithSumSegment() {
    final key = '$_eventKey With Sum Segment';
    Countly.startEvent(key);
    Timer(const Duration(seconds: 5), () {
      var event = {'key': key, 'count': _count, 'sum': _sum};
      event['segmentation'] = _segmentation;
      Countly.endEvent(event);
    });
  }

  void cancelEvent() {
    final key = '$_eventKey Cancel';
    Countly.startEvent(key);
    Timer(const Duration(seconds: 5), () {
      Countly.instance.events.cancelEvent(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Event parameters form
          CountlySection(
            title: 'Event Parameters',
            subtitle: 'Values used by the buttons below',
            children: [
              TextField(controller: _eventKeyController, decoration: InputDecoration(labelText: 'Event Key')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _countController, decoration: InputDecoration(labelText: 'Count'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _sumController, decoration: InputDecoration(labelText: 'Sum'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmentation entries
          CountlySection(
            title: 'Segmentation',
            subtitle: 'Add key-value pairs for event segmentation',
            children: [
              for (int i = 0; i < _segmentations.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _segmentations[i].keyController, decoration: InputDecoration(labelText: 'Key'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _segmentations[i].valueController, decoration: InputDecoration(labelText: 'Value'))),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: _segmentations.length > 1 ? () => _removeSegmentation(i) : null,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addSegmentation,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Segmentation'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Basic events
          CountlySection(
            title: 'Basic Events',
            children: [
              MyButton(text: 'Basic Event', type: CountlyButtonType.filled, onPressed: basicEvent),
              MyButton(text: 'Event with Sum', type: CountlyButtonType.tonal, onPressed: eventWithSum),
              MyButton(text: 'Event with Segment', type: CountlyButtonType.tonal, onPressed: eventWithSegment),
              MyButton(text: 'Event with Sum and Segment', type: CountlyButtonType.tonal, onPressed: eventWithSumSegment),
            ],
          ),
          const SizedBox(height: 16),

          // Timed events
          CountlySection(
            title: 'Timed Events',
            subtitle: 'Each starts a timer, ends after 5 seconds',
            children: [
              MyButton(text: 'Timed Event Start/Stop', type: CountlyButtonType.filled, onPressed: endEventBasic),
              MyButton(text: 'Timed Event Sum Start/Stop', type: CountlyButtonType.tonal, onPressed: endEventWithSum),
              MyButton(text: 'Timed Event Segment Start/Stop', type: CountlyButtonType.tonal, onPressed: endEventWithSegment),
              MyButton(text: 'Timed Event Sum Segment Start/Stop', type: CountlyButtonType.tonal, onPressed: endEventWithSumSegment),
              MyButton(text: 'Timed Event Start/Cancel', type: CountlyButtonType.outlined, onPressed: cancelEvent),
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
