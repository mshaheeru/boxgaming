import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import '../bloc/venue_management_bloc.dart';
import '../bloc/venue_management_event.dart';
import '../bloc/venue_management_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/domain/entities/ground_entity.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';
import '../widgets/multi_step_venue_form.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/venue_management_remote_datasource.dart';
import '../../../../core/error/exceptions.dart';

class VenueManagementPage extends StatelessWidget {
  const VenueManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<VenueManagementBloc>()..add(LoadMyVenuesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Venue Management'),
        ),
        body: BlocConsumer<VenueManagementBloc, VenueManagementState>(
          listener: (context, state) {
            if (state is PhotoUploaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is VenueManagementError) {
              // Only show error snackbar if it's not a photo upload error (those are handled above)
              if (!state.message.contains('photo') && !state.message.contains('bucket')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state.message.contains('photo') || state.message.contains('bucket')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is VenueManagementLoading) {
              return const LoadingWidget(message: 'Loading venues...');
            }

            if (state is VenueManagementError) {
              return ErrorDisplayWidget(
                message: state.message,
                onRetry: () {
                  context.read<VenueManagementBloc>().add(LoadMyVenuesEvent());
                },
              );
            }

            if (state is VenuesLoaded) {
              return _VenuesList(venues: state.venues);
            }

            // If state is PhotoUploaded or VenueUpdated, show the current venues
            if (state is PhotoUploaded || state is VenueUpdated) {
              // The bloc will emit VenuesLoaded after reloading
              return const LoadingWidget(message: 'Refreshing...');
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showCreateVenueDialog(context);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateVenueDialog(BuildContext context) {
    // Get the bloc from the current context
    final bloc = context.read<VenueManagementBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: const MultiStepVenueForm(),
      ),
    );
  }

  void _showCreateVenueDialogOld(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Venue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }

              final dto = CreateVenueDto(
                name: nameController.text,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                address: addressController.text.isEmpty
                    ? null
                    : addressController.text,
                city: cityController.text.isEmpty ? null : cityController.text,
              );

              context.read<VenueManagementBloc>().add(CreateVenueEvent(dto));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venue created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _VenuesList extends StatelessWidget {
  final List<VenueEntity> venues;

  const _VenuesList({required this.venues});

  @override
  Widget build(BuildContext context) {
    if (venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No venues yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to create your first venue',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<VenueManagementBloc>().add(LoadMyVenuesEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: venues.length,
        itemBuilder: (context, index) {
          final venue = venues[index];
          return _VenueCard(venue: venue);
        },
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final VenueEntity venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue photo
          if (venue.photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                venue.photos.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
          // Venue details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (venue.city != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              venue.city!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusChip(isActive: venue.isActive),
                  ],
                ),
                if (venue.description != null && venue.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    venue.description!,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditVenueDialog(context, venue),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: venue.isActive
                          ? OutlinedButton.icon(
                              onPressed: () {
                                context.read<VenueManagementBloc>().add(
                                      DeactivateVenueEvent(venue.id),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Venue deactivated'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_off, size: 18),
                              label: const Text('Deactivate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                context.read<VenueManagementBloc>().add(
                                      ActivateVenueEvent(venue.id),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Venue activated'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 18),
                              label: const Text('Activate'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVenueDialog(BuildContext context, VenueEntity venue) {
    // Get bloc from the outer context (which has access to the provider)
    final bloc = context.read<VenueManagementBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: MultiStepVenueForm(venue: venue),
      ),
    );
  }
}

class _EditVenueDialog extends StatefulWidget {
  final VenueEntity venue;
  final VenueManagementBloc bloc;

  const _EditVenueDialog({
    required this.venue,
    required this.bloc,
  });

  @override
  State<_EditVenueDialog> createState() => _EditVenueDialogState();
}

class _EditVenueDialogState extends State<_EditVenueDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  File? _selectedPhoto;
  VenueEntity? _currentVenue;
  List<GroundEntity> _grounds = [];
  bool _loadingGrounds = false;
  final VenueManagementRemoteDataSource _remoteDataSource = 
      GetIt.instance<VenueManagementRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _currentVenue = widget.venue;
    _grounds = List.from(widget.venue.grounds);
    _nameController = TextEditingController(text: widget.venue.name);
    _descriptionController =
        TextEditingController(text: widget.venue.description ?? '');
    _addressController = TextEditingController(text: widget.venue.address ?? '');
    _cityController = TextEditingController(text: widget.venue.city ?? '');
    _loadGrounds();
  }

  Future<void> _loadGrounds() async {
    setState(() {
      _loadingGrounds = true;
    });
    try {
      final groundsData = await _remoteDataSource.getVenueGrounds(widget.venue.id);
      setState(() {
        _grounds = groundsData.map((g) {
          // Convert API response to GroundEntity
          return GroundEntity(
            id: g['id'] as String,
            venueId: widget.venue.id,
            name: g['name'] as String,
            sportType: _parseSportType(g['sport_type'] as String),
            size: _parseGroundSize(g['size'] as String),
            price2hr: (g['price_2hr'] as num).toDouble(),
            price3hr: (g['price_3hr'] as num).toDouble(),
            isActive: g['is_active'] as bool? ?? true,
          );
        }).toList();
        _loadingGrounds = false;
      });
    } catch (e) {
      setState(() {
        _loadingGrounds = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load grounds: ${e.toString()}')),
        );
      }
    }
  }

  SportType _parseSportType(String value) {
    switch (value) {
      case 'badminton':
        return SportType.badminton;
      case 'futsal':
        return SportType.futsal;
      case 'cricket':
        return SportType.cricket;
      case 'padel':
        return SportType.padel;
      case 'table_tennis':
        return SportType.tableTennis;
      default:
        return SportType.badminton;
    }
  }

  GroundSize _parseGroundSize(String value) {
    switch (value) {
      case 'small':
        return GroundSize.small;
      case 'medium':
        return GroundSize.medium;
      case 'large':
        return GroundSize.large;
      default:
        return GroundSize.medium;
    }
  }

  String _sportTypeToString(SportType type) {
    switch (type) {
      case SportType.badminton:
        return 'badminton';
      case SportType.futsal:
        return 'futsal';
      case SportType.cricket:
        return 'cricket';
      case SportType.padel:
        return 'padel';
      case SportType.tableTennis:
        return 'table_tennis';
      case SportType.all:
        return 'all';
    }
  }

  String _groundSizeToString(GroundSize size) {
    switch (size) {
      case GroundSize.small:
        return 'small';
      case GroundSize.medium:
        return 'medium';
      case GroundSize.large:
        return 'large';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the current venue (which may be updated) or fallback to widget.venue
    final venue = _currentVenue ?? widget.venue;
    
    return BlocListener<VenueManagementBloc, VenueManagementState>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (state is VenueUpdated) {
          // Update the current venue when it's updated
          setState(() {
            _currentVenue = state.venue;
          });
        } else if (state is PhotoUploaded) {
          // Reload venues to get the updated photo
          widget.bloc.add(LoadMyVenuesEvent());
        }
      },
      child: BlocBuilder<VenueManagementBloc, VenueManagementState>(
        bloc: widget.bloc,
        builder: (context, state) {
          // If venue was updated, use the updated venue
          if (state is VenuesLoaded) {
            final updatedVenue = state.venues.firstWhere(
              (v) => v.id == widget.venue.id,
              orElse: () => venue,
            );
            if (updatedVenue.id == widget.venue.id && updatedVenue != _currentVenue) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _currentVenue = updatedVenue;
                });
              });
            }
          }
          
          return AlertDialog(
      title: const Text('Edit Venue'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Photo upload section
            const Text(
              'Venue Photo (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedPhoto != null
                    ? Image.file(
                        _selectedPhoto!,
                        fit: BoxFit.cover,
                      )
                    : venue.photos.isNotEmpty
                        ? Image.network(
                            venue.photos.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.add_photo_alternate, size: 48),
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48),
                                SizedBox(height: 8),
                                Text('Tap to add photo'),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 24),
            // Grounds Management Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grounds Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: () => _showAddGroundDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Ground'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingGrounds)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_grounds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No grounds yet. Add your first ground!',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...List.generate(_grounds.length, (index) {
                return _EditGroundCard(
                  ground: _grounds[index],
                  onUpdate: (updatedGround) async {
                    await _updateGround(updatedGround);
                  },
                  onDelete: () async {
                    await _deleteGround(_grounds[index].id);
                  },
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is required')),
              );
              return;
            }

            final dto = UpdateVenueDto(
              name: _nameController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              address: _addressController.text.isEmpty
                  ? null
                  : _addressController.text,
              city: _cityController.text.isEmpty ? null : _cityController.text,
            );

            widget.bloc.add(UpdateVenueEvent(widget.venue.id, dto));

            // Upload photo if selected (non-blocking)
            if (_selectedPhoto != null) {
              widget.bloc.add(
                UploadVenuePhotoEvent(widget.venue.id, _selectedPhoto!.path),
              );
            }

            Navigator.pop(context);
            // Note: Snackbar is shown by BlocListener in the parent
          },
          child: const Text('Update'),
        ),
      ],
          );
        },
      ),
    );
  }

  Future<void> _updateGround(GroundEntity ground) async {
    try {
      await _remoteDataSource.updateGround(
        widget.venue.id,
        ground.id,
        {
          'name': ground.name,
          'sportType': _sportTypeToString(ground.sportType),
          'size': _groundSizeToString(ground.size),
          'price2hr': ground.price2hr,
          'price3hr': ground.price3hr,
          'isActive': ground.isActive,
        },
      );
      await _loadGrounds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ground updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ground: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGround(String groundId) async {
    try {
      await _remoteDataSource.deleteGround(widget.venue.id, groundId);
      await _loadGrounds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ground deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ground: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddGroundDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddGroundDialog(),
    );

    if (result != null) {
      try {
        await _remoteDataSource.createGround(widget.venue.id, {
          'name': result['name'],
          'sportType': result['sportType'],
          'size': result['size'],
          'price2hr': result['price2hr'],
          'price3hr': result['price3hr'],
        });
        await _loadGrounds();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ground added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add ground: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _EditGroundCard extends StatefulWidget {
  final GroundEntity ground;
  final Function(GroundEntity) onUpdate;
  final VoidCallback onDelete;

  const _EditGroundCard({
    required this.ground,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_EditGroundCard> createState() => _EditGroundCardState();
}

class _EditGroundCardState extends State<_EditGroundCard> {
  late TextEditingController _nameController;
  late TextEditingController _price2hrController;
  late TextEditingController _price3hrController;
  late String _sportType;
  late String _size;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ground.name);
    _price2hrController = TextEditingController(text: widget.ground.price2hr.toString());
    _price3hrController = TextEditingController(text: widget.ground.price3hr.toString());
    _sportType = _sportTypeToString(widget.ground.sportType);
    _size = _groundSizeToString(widget.ground.size);
    _isActive = widget.ground.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _price2hrController.dispose();
    _price3hrController.dispose();
    super.dispose();
  }

  String _sportTypeToString(SportType type) {
    switch (type) {
      case SportType.badminton:
        return 'badminton';
      case SportType.futsal:
        return 'futsal';
      case SportType.cricket:
        return 'cricket';
      case SportType.padel:
        return 'padel';
      case SportType.tableTennis:
        return 'table_tennis';
      case SportType.all:
        return 'all';
    }
  }

  String _groundSizeToString(GroundSize size) {
    switch (size) {
      case GroundSize.small:
        return 'small';
      case GroundSize.medium:
        return 'medium';
      case GroundSize.large:
        return 'large';
    }
  }

  SportType _parseSportType(String value) {
    switch (value) {
      case 'badminton':
        return SportType.badminton;
      case 'futsal':
        return SportType.futsal;
      case 'cricket':
        return SportType.cricket;
      case 'padel':
        return SportType.padel;
      case 'table_tennis':
        return SportType.tableTennis;
      default:
        return SportType.badminton;
    }
  }

  GroundSize _parseGroundSize(String value) {
    switch (value) {
      case 'small':
        return GroundSize.small;
      case 'medium':
        return GroundSize.medium;
      case 'large':
        return GroundSize.large;
      default:
        return GroundSize.medium;
    }
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ground name is required')),
      );
      return;
    }

    final price2hr = double.tryParse(_price2hrController.text);
    final price3hr = double.tryParse(_price3hrController.text);

    if (price2hr == null || price2hr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 2hr price')),
      );
      return;
    }

    if (price3hr == null || price3hr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 3hr price')),
      );
      return;
    }

    widget.onUpdate(GroundEntity(
      id: widget.ground.id,
      venueId: widget.ground.venueId,
      name: _nameController.text.trim(),
      sportType: _parseSportType(_sportType),
      size: _parseGroundSize(_size),
      price2hr: price2hr,
      price3hr: price3hr,
      isActive: _isActive,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.ground.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                    _save();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ground Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sportType,
              decoration: const InputDecoration(
                labelText: 'Sport Type *',
                border: OutlineInputBorder(),
                isDense: true,
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
                _save();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _size,
              decoration: const InputDecoration(
                labelText: 'Size *',
                border: OutlineInputBorder(),
                isDense: true,
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
                _save();
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
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _save(),
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
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _save(),
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

class _AddGroundDialog extends StatefulWidget {
  @override
  State<_AddGroundDialog> createState() => _AddGroundDialogState();
}

class _AddGroundDialogState extends State<_AddGroundDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _price2hrController = TextEditingController();
  final TextEditingController _price3hrController = TextEditingController();
  String _sportType = 'badminton';
  String _size = 'medium';

  @override
  void dispose() {
    _nameController.dispose();
    _price2hrController.dispose();
    _price3hrController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ground name is required')),
      );
      return;
    }

    final price2hr = double.tryParse(_price2hrController.text);
    final price3hr = double.tryParse(_price3hrController.text);

    if (price2hr == null || price2hr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 2hr price')),
      );
      return;
    }

    if (price3hr == null || price3hr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 3hr price')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'sportType': _sportType,
      'size': _size,
      'price2hr': price2hr,
      'price3hr': price3hr,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Ground'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ground Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
              },
            ),
            const SizedBox(height: 16),
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
              },
            ),
            const SizedBox(height: 16),
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive'),
      backgroundColor: isActive
          ? Colors.green.withOpacity(0.2)
          : Colors.grey.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isActive ? Colors.green : Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

