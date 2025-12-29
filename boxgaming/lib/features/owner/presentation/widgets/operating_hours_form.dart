import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OperatingHoursForm extends StatefulWidget {
  final List<Map<String, dynamic>> operatingHours;
  final Function(List<Map<String, dynamic>>) onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OperatingHoursForm({
    super.key,
    required this.operatingHours,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OperatingHoursForm> createState() => _OperatingHoursFormState();
}

class _OperatingHoursFormState extends State<OperatingHoursForm> {
  final Map<int, Map<String, String>> _hours = {};
  final Map<int, TimeOfDay?> _openTimes = {};
  final Map<int, TimeOfDay?> _closeTimes = {};

  final List<String> _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize from existing data
    for (var hour in widget.operatingHours) {
      final day = hour['day_of_week'] as int;
      final openTime = hour['open_time'] as String;
      final closeTime = hour['close_time'] as String;
      
      _hours[day] = {'open': openTime, 'close': closeTime};
      
      final openParts = openTime.split(':');
      _openTimes[day] = TimeOfDay(
        hour: int.parse(openParts[0]),
        minute: int.parse(openParts[1]),
      );
      
      final closeParts = closeTime.split(':');
      _closeTimes[day] = TimeOfDay(
        hour: int.parse(closeParts[0]),
        minute: int.parse(closeParts[1]),
      );
    }
  }

  Future<void> _selectOpenTime(int day) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _openTimes[day] ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _openTimes[day] = picked;
        _updateHours(day);
      });
    }
  }

  Future<void> _selectCloseTime(int day) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _closeTimes[day] ?? const TimeOfDay(hour: 22, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _closeTimes[day] = picked;
        _updateHours(day);
      });
    }
  }

  void _updateHours(int day) {
    if (_openTimes[day] != null && _closeTimes[day] != null) {
      final openTime = _formatTime(_openTimes[day]!);
      final closeTime = _formatTime(_closeTimes[day]!);
      
      _hours[day] = {'open': openTime, 'close': closeTime};
      
      // Update parent
      final hoursList = _hours.entries.map((e) {
        return {
          'day_of_week': e.key,
          'open_time': e.value['open'],
          'close_time': e.value['close'],
        };
      }).toList();
      
      widget.onChanged(hoursList);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _toggleDay(int day) {
    setState(() {
      if (_hours.containsKey(day)) {
        _hours.remove(day);
        _openTimes.remove(day);
        _closeTimes.remove(day);
      } else {
        _openTimes[day] = const TimeOfDay(hour: 9, minute: 0);
        _closeTimes[day] = const TimeOfDay(hour: 22, minute: 0);
        _updateHours(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Operating Hours',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set operating hours for each day of the week',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...List.generate(7, (index) {
            final isEnabled = _hours.containsKey(index);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isEnabled,
                          onChanged: (_) => _toggleDay(index),
                        ),
                        Text(
                          _days[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isEnabled ? null : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (isEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _selectOpenTime(index),
                              child: Text(
                                _openTimes[index] != null
                                    ? _formatTime(_openTimes[index]!)
                                    : 'Open Time',
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('to'),
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _selectCloseTime(index),
                              child: Text(
                                _closeTimes[index] != null
                                    ? _formatTime(_closeTimes[index]!)
                                    : 'Close Time',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  child: const Text('Next: Add Grounds'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

