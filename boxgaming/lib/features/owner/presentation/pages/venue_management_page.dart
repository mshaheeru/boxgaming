import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/venue_management_bloc.dart';
import '../bloc/venue_management_event.dart';
import '../bloc/venue_management_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';

class VenueManagementPage extends StatelessWidget {
  const VenueManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<VenueManagementBloc>()
        ..add(LoadMyVenuesEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Venue Management'),
        ),
        body: BlocBuilder<VenueManagementBloc, VenueManagementState>(
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
      child: Padding(
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
    );
  }

  void _showEditVenueDialog(BuildContext context, VenueEntity venue) {
    final nameController = TextEditingController(text: venue.name);
    final descriptionController =
        TextEditingController(text: venue.description ?? '');
    final addressController = TextEditingController(text: venue.address ?? '');
    final cityController = TextEditingController(text: venue.city ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Venue'),
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

              final dto = UpdateVenueDto(
                name: nameController.text,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                address: addressController.text.isEmpty
                    ? null
                    : addressController.text,
                city: cityController.text.isEmpty ? null : cityController.text,
              );

              context
                  .read<VenueManagementBloc>()
                  .add(UpdateVenueEvent(venue.id, dto));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venue updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
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

