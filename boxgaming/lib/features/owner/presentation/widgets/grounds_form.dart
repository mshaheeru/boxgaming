import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../venues/domain/entities/ground_entity.dart';

class GroundsForm extends StatefulWidget {
  final List<Map<String, dynamic>> grounds;
  final String venueId;
  final Function(List<Map<String, dynamic>>) onChanged;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const GroundsForm({
    super.key,
    required this.grounds,
    required this.venueId,
    required this.onChanged,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<GroundsForm> createState() => _GroundsFormState();
}

class _GroundsFormState extends State<GroundsForm> {
  final List<Map<String, dynamic>> _grounds = [];
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  @override
  void initState() {
    super.initState();
    _grounds.addAll(widget.grounds);
  }

  void _addGround() {
    setState(() {
      _grounds.add({
        'name': '',
        'sportType': 'badminton',
        'size': 'medium',
        'price2hr': 0.0,
        'price3hr': 0.0,
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

    // Create all grounds
    try {
      for (var ground in _grounds) {
        await _apiClient.dio.post(
          ApiConstants.venueGrounds(widget.venueId),
          data: {
            'name': ground['name'],
            'sportType': ground['sportType'],
            'size': ground['size'],
            'price2hr': ground['price2hr'],
            'price3hr': ground['price3hr'],
          },
        );
      }

      // All grounds created successfully
      // Now complete setup (activate venue) - this will be handled by the parent widget's bloc listener
      widget.onComplete();
    } catch (e) {
      if (e is ServerException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create grounds: ${e.toString()}')),
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
                  child: const Text('Complete Setup'),
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _price2hrController.dispose();
    _price3hrController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onUpdate({
      'name': _nameController.text.trim(),
      'sportType': _sportType,
      'size': _size,
      'price2hr': double.tryParse(_price2hrController.text) ?? 0.0,
      'price3hr': double.tryParse(_price3hrController.text) ?? 0.0,
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
            DropdownButtonFormField<String>(
              value: _sportType,
              decoration: const InputDecoration(
                labelText: 'Sport Type *',
                border: OutlineInputBorder(),
              ),
              items: ['badminton', 'futsal', 'cricket', 'padel', 'table_tennis'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase().replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _sportType = value!;
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
          ],
        ),
      ),
    );
  }
}

