import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../venues/domain/entities/ground_entity.dart';
import '../../data/datasources/venue_management_remote_datasource.dart';

class GroundsForm extends StatefulWidget {
  final List<Map<String, dynamic>> grounds;
  final String venueId;
  final Function(List<Map<String, dynamic>>) onChanged;
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final bool isEditMode;

  const GroundsForm({
    super.key,
    required this.grounds,
    required this.venueId,
    required this.onChanged,
    required this.onComplete,
    required this.onBack,
    this.isEditMode = false,
  });

  @override
  State<GroundsForm> createState() => _GroundsFormState();
}

class _GroundsFormState extends State<GroundsForm> {
  final List<Map<String, dynamic>> _grounds = [];
  final ApiClient _apiClient = GetIt.instance<ApiClient>();
  final VenueManagementRemoteDataSource _remoteDataSource = 
      GetIt.instance<VenueManagementRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _grounds.addAll(widget.grounds);
  }

  void _addGround() {
    setState(() {
      _grounds.add({
        'id': null, // New grounds have no ID - this prevents duplicate creation
        'name': '',
        'sportType': 'badminton',
        'size': 'medium',
        'price2hr': 0.0,
        'price3hr': 0.0,
        'operatingHours': <Map<String, dynamic>>[], // Add operating hours for each ground
      });
    });
    widget.onChanged(_grounds);
  }

  void _removeGround(int index) {
    setState(() {
      _grounds.removeAt(index);
    });
    widget.onChanged(_grounds);
  }

  void _updateGround(int index, Map<String, dynamic> ground) {
    setState(() {
      _grounds[index] = ground;
    });
    widget.onChanged(_grounds);
  }

  Future<void> _saveGrounds() async {
    if (_grounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ground')),
      );
      return;
    }

    // Validate all grounds
    for (var i = 0; i < _grounds.length; i++) {
      final ground = _grounds[i];
      if (ground['name'] == null || (ground['name'] as String).trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ground ${i + 1}: Please enter a name')),
        );
        return;
      }
      if (ground['price2hr'] == null || ground['price2hr'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ground ${i + 1}: Please enter a valid 2hr price')),
        );
        return;
      }
      if (ground['price3hr'] == null || ground['price3hr'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ground ${i + 1}: Please enter a valid 3hr price')),
        );
        return;
      }
    }

    // Create or update all grounds
    try {
      for (var i = 0; i < _grounds.length; i++) {
        final ground = _grounds[i];
        final sportType = ground['sportType'] as String;
        final groundId = ground['id'] as String?;
        String? finalGroundId;
        
        // Determine if this is an existing ground (has ID and we're in edit mode)
        final isExistingGround = groundId != null && 
                                 groundId.isNotEmpty && 
                                 widget.isEditMode;
        
        if (isExistingGround) {
          // Update existing ground - preserve the ID
          await _remoteDataSource.updateGround(widget.venueId, groundId!, {
            'name': ground['name'],
            'sportType': sportType, // Can be 'all' or specific sport
            'size': ground['size'],
            'price2hr': ground['price2hr'],
            'price3hr': ground['price3hr'],
          });
          finalGroundId = groundId; // Use existing ID
          
          // Update the ground in our list to preserve the ID
          _grounds[i] = {
            ...ground,
            'id': groundId, // Ensure ID is preserved
          };
        } else {
          // Create new ground (no ID or not in edit mode)
          final createdGround = await _remoteDataSource.createGround(widget.venueId, {
            'name': ground['name'],
            'sportType': sportType, // Can be 'all' or specific sport
            'size': ground['size'],
            'price2hr': ground['price2hr'],
            'price3hr': ground['price3hr'],
          });
          finalGroundId = createdGround['id'] as String?;
          
          // Update the ground in our list with the new ID
          if (finalGroundId != null) {
            _grounds[i] = {
              ...ground,
              'id': finalGroundId, // Set the new ID
            };
          }
        }

        // Save operating hours for this ground if provided
        final operatingHours = ground['operatingHours'] as List<dynamic>?;
        if (finalGroundId != null && operatingHours != null && operatingHours.isNotEmpty) {
          // Convert to the format expected by the API
          final formattedHours = operatingHours.map((oh) {
            final hourMap = oh as Map<String, dynamic>;
            return {
              'day_of_week': hourMap['day_of_week'] ?? hourMap['dayOfWeek'],
              'open_time': hourMap['open_time'] ?? hourMap['openTime'],
              'close_time': hourMap['close_time'] ?? hourMap['closeTime'],
            };
          }).toList();
          
          // Always create/update operating hours (API handles replacement)
          await _remoteDataSource.createGroundOperatingHours(
            widget.venueId,
            finalGroundId,
            formattedHours,
          );
        }
      }

      // All grounds created/updated successfully
      widget.onComplete();
    } catch (e) {
      if (e is ServerException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save grounds: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add Grounds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add at least one ground for customers to book',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...List.generate(_grounds.length, (index) {
            return _GroundCard(
              ground: _grounds[index],
              index: index,
              onUpdate: (ground) => _updateGround(index, ground),
              onRemove: () => _removeGround(index),
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addGround,
            icon: const Icon(Icons.add),
            label: const Text('Add Ground'),
          ),
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
                  onPressed: _saveGrounds,
                  child: Text(widget.isEditMode ? 'Save Changes' : 'Complete Setup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroundCard extends StatefulWidget {
  final Map<String, dynamic> ground;
  final int index;
  final Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onRemove;

  const _GroundCard({
    required this.ground,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_GroundCard> createState() => _GroundCardState();
}

class _GroundCardState extends State<_GroundCard> {
  late TextEditingController _nameController;
  late TextEditingController _price2hrController;
  late TextEditingController _price3hrController;
  late String _sportType;
  late String _size;
  bool _showOperatingHours = false;
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
    _nameController = TextEditingController(text: widget.ground['name'] ?? '');
    _price2hrController = TextEditingController(
      text: widget.ground['price2hr']?.toString() ?? '0',
    );
    _price3hrController = TextEditingController(
      text: widget.ground['price3hr']?.toString() ?? '0',
    );
    _sportType = widget.ground['sportType'] ?? 'badminton';
    _size = widget.ground['size'] ?? 'medium';
    
    // Initialize operating hours from existing data
    final existingHours = widget.ground['operatingHours'] as List<dynamic>? ?? [];
    for (var hour in existingHours) {
      if (hour is Map<String, dynamic>) {
        final day = hour['day_of_week'] ?? hour['dayOfWeek'] as int?;
        final openTime = hour['open_time'] ?? hour['openTime'] as String?;
        final closeTime = hour['close_time'] ?? hour['closeTime'] as String?;
        
        if (day != null && openTime != null && closeTime != null) {
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _price2hrController.dispose();
    _price3hrController.dispose();
    super.dispose();
  }

  void _update() {
    // Convert operating hours to list format
    final hoursList = _hours.entries.map((e) {
      return {
        'day_of_week': e.key,
        'open_time': e.value['open'],
        'close_time': e.value['close'],
      };
    }).toList();
    
    widget.onUpdate({
      'name': _nameController.text.trim(),
      'sportType': _sportType,
      'size': _size,
      'price2hr': double.tryParse(_price2hrController.text) ?? 0.0,
      'price3hr': double.tryParse(_price3hrController.text) ?? 0.0,
      'operatingHours': hoursList,
    });
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
      _update();
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ground ${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ground Name *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _update(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sport Types *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _SportTypeChipSelector(
              selectedSports: _sportType == 'all' 
                  ? ['all'] 
                  : (_sportType.isNotEmpty ? [_sportType] : []),
              onChanged: (selected) {
                setState(() {
                  // If "all" is selected, set sportType to 'all'
                  // Otherwise, use the first selected sport (since DB only supports one)
                  if (selected.contains('all')) {
                    _sportType = 'all';
                  } else if (selected.isNotEmpty) {
                    _sportType = selected.first;
                  } else {
                    _sportType = '';
                  }
                });
                _update();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _size,
              decoration: const InputDecoration(
                labelText: 'Size *',
                border: OutlineInputBorder(),
              ),
              items: ['small', 'medium', 'large'].map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _size = value!;
                });
                _update();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _price2hrController,
                    decoration: const InputDecoration(
                      labelText: '2hr Price *',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _price3hrController,
                    decoration: const InputDecoration(
                      labelText: '3hr Price *',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Operating Hours Section
            ExpansionTile(
              title: const Text(
                'Operating Hours',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _hours.isEmpty 
                    ? 'Tap to set operating hours' 
                    : '${_hours.length} day(s) configured',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              initiallyExpanded: _showOperatingHours,
              onExpansionChanged: (expanded) {
                setState(() {
                  _showOperatingHours = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: List.generate(7, (index) {
                      final isEnabled = _hours.containsKey(index);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isEnabled ? null : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              if (isEnabled) ...[
                                const SizedBox(height: 8),
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SportTypeChipSelector extends StatefulWidget {
  final List<String> selectedSports;
  final Function(List<String>) onChanged;

  const _SportTypeChipSelector({
    required this.selectedSports,
    required this.onChanged,
  });

  @override
  State<_SportTypeChipSelector> createState() => _SportTypeChipSelectorState();
}

class _SportTypeChipSelectorState extends State<_SportTypeChipSelector> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedSports);
  }

  @override
  void didUpdateWidget(_SportTypeChipSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSports != widget.selectedSports) {
      _selected = List.from(widget.selectedSports);
    }
  }

  void _toggleSport(String sport) {
    setState(() {
      if (sport == 'all') {
        // If "all" is selected, clear other selections and select only "all"
        _selected = ['all'];
      } else {
        // Remove "all" if it was selected
        _selected.remove('all');
        
        if (_selected.contains(sport)) {
          _selected.remove(sport);
        } else {
          _selected.add(sport);
        }
        
        // If all sports are selected, replace with "all"
        final allSports = ['badminton', 'futsal', 'cricket', 'padel', 'table_tennis'];
        if (_selected.length == allSports.length && 
            _selected.every((s) => allSports.contains(s))) {
          _selected = ['all'];
        }
      }
      widget.onChanged(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSports = ['all', 'badminton', 'futsal', 'cricket', 'padel', 'table_tennis'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allSports.map((sport) {
        final isSelected = _selected.contains(sport);
        final displayName = sport == 'all' 
            ? 'All' 
            : sport.toUpperCase().replaceAll('_', ' ');
        
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.close, size: 16),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (_) => _toggleSport(sport),
          selectedColor: Colors.blue.withOpacity(0.2),
          checkmarkColor: Colors.transparent, // Hide default checkmark
        );
      }).toList(),
    );
  }
}

